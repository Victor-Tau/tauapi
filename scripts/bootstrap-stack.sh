#!/usr/bin/env bash
# Idempotently prepare secrets, render the stack, and start the data layer and
# backend instances. Never regenerates existing secrets, never recreates
# volumes, never opens the public site (Nginx mode is managed separately).
#
# Usage: sudo bootstrap-stack.sh [--backend-image IMAGE] [--with-slave] [--nginx maintenance|live|keep]
# Exit codes: 0 ok, 2 usage, 3 missing input, 6 service failed to become healthy.
source "$(dirname "$0")/lib.sh"
require_root

BACKEND_IMAGE=""
WITH_SLAVE=0
NGINX_MODE=keep
while [[ $# -gt 0 ]]; do
  case "$1" in
    --backend-image) BACKEND_IMAGE="$2"; shift 2 ;;
    --with-slave) WITH_SLAVE=1; shift ;;
    --nginx) NGINX_MODE="$2"; shift 2 ;;
    *) die "unknown argument $1" 2 ;;
  esac
done
acquire_lock

POSTGRES_IMAGE_PIN="postgres:16-bookworm@sha256:e8a07d2c7579b038938cdba6c539e580e5001caf9ea203d397b5cc83e76bd938"
REDIS_IMAGE_PIN="redis:7.4-bookworm@sha256:b6b6e3dc0c0952737748e55d5d885272840c7e42ba41ab1d5489f693419882f5"

install -d -m 0700 -o root -g root "$SECRET_ROOT"
install -d -m 0750 -o root -g root "$STACK_DIR" "$STATE_DIR"

gen_secret() { python3 -I -c 'import secrets,string;a=string.ascii_letters+string.digits;print("".join(secrets.choice(a) for _ in range(int(__import__("sys").argv[1]))))' "$1"; }

# --- secrets: read existing first, generate only when absent ---------------
write_secret_file() { # path content
  local tmp
  tmp=$(mktemp "$SECRET_ROOT/.tmp.XXXXXX")
  chmod 0600 "$tmp"
  printf '%s\n' "$2" > "$tmp"
  mv -f "$tmp" "$1"
}
if [[ ! -s $SECRET_ROOT/postgres.env ]]; then
  write_secret_file "$SECRET_ROOT/postgres.env" "POSTGRES_PASSWORD=$(gen_secret 40)"
  log "generated postgres secret"
fi
if [[ ! -s $SECRET_ROOT/redis.env ]]; then
  write_secret_file "$SECRET_ROOT/redis.env" "REDIS_PASSWORD=$(gen_secret 40)"
  log "generated redis secret"
fi
if [[ ! -s $SECRET_ROOT/app-secrets.env ]]; then
  write_secret_file "$SECRET_ROOT/app-secrets.env" "SESSION_SECRET=$(gen_secret 64)
CRYPTO_SECRET=$(gen_secret 64)"
  log "generated session/crypto secrets"
fi
PG_PW=$(sed -n 's/^POSTGRES_PASSWORD=//p' "$SECRET_ROOT/postgres.env")
RD_PW=$(sed -n 's/^REDIS_PASSWORD=//p' "$SECRET_ROOT/redis.env")
[[ -n $PG_PW && -n $RD_PW ]] || die "secret files present but empty values" 3

# backend.env is derived (not random) and can be re-rendered safely.
{
  echo "# Rendered by bootstrap-stack.sh; derived from postgres.env, redis.env, app-secrets.env"
  echo "SQL_DSN=postgresql://tauapi:${PG_PW}@postgres:5432/tauapi?sslmode=disable"
  echo "REDIS_CONN_STRING=redis://:${RD_PW}@redis:6379/0"
  cat "$SECRET_ROOT/app-secrets.env"
  cat <<EOF
SESSION_COOKIE_SECURE=true
SESSION_COOKIE_TRUSTED_URL=$TAUAPI_ORIGIN
SHUTDOWN_TIMEOUT_SECONDS=120
TRUSTED_PROXIES=$EDGE_GATEWAY/32
TZ=Asia/Singapore
FRONTEND_BASE_URL=
SQL_MAX_OPEN_CONNS=25
SQL_MAX_IDLE_CONNS=5
SQL_MAX_LIFETIME=300
BATCH_UPDATE_ENABLED=true
ERROR_LOG_ENABLED=true
MEMORY_CACHE_ENABLED=true
SYNC_FREQUENCY=60
GIN_MODE=release
ENABLE_PPROF=false
DEFAULT_LANGUAGE=en
EOF
  if [[ $TAUAPI_ENV == qa ]]; then
    # QA only: automated browser review performs hundreds of full page loads
    # (each bootstraps /api/user/auth/refresh) and repeated logins from
    # 127.0.0.1. Production keeps the upstream defaults (20 per 20 min).
    echo "CRITICAL_RATE_LIMIT=100000"
    echo "GLOBAL_WEB_RATE_LIMIT=100000"
    echo "GLOBAL_API_RATE_LIMIT=100000"
  fi
} > "$SECRET_ROOT/.backend.env.tmp"
chmod 0600 "$SECRET_ROOT/.backend.env.tmp"
mv -f "$SECRET_ROOT/.backend.env.tmp" "$SECRET_ROOT/backend.env"
unset PG_PW RD_PW

# --- render stack ---------------------------------------------------------
install -m 0640 "$OPS_ROOT/templates/compose.yml" "$COMPOSE_FILE"
if [[ -f $IMAGES_ENV ]]; then
  # shellcheck disable=SC1090
  source "$IMAGES_ENV"
fi
BACKEND_MASTER_IMAGE=${BACKEND_IMAGE:-${BACKEND_MASTER_IMAGE:-}}
BACKEND_SLAVE_IMAGE=${BACKEND_SLAVE_IMAGE:-$BACKEND_MASTER_IMAGE}
[[ -n $BACKEND_MASTER_IMAGE ]] || die "no backend image: pass --backend-image on first run" 3
if [[ -n $BACKEND_IMAGE && $WITH_SLAVE == 1 ]]; then BACKEND_SLAVE_IMAGE=$BACKEND_IMAGE; fi
cat > "$IMAGES_ENV.tmp" <<EOF
POSTGRES_IMAGE=$POSTGRES_IMAGE_PIN
REDIS_IMAGE=$REDIS_IMAGE_PIN
BACKEND_MASTER_IMAGE=$BACKEND_MASTER_IMAGE
BACKEND_SLAVE_IMAGE=$BACKEND_SLAVE_IMAGE
MOCK_IMAGE=python:3.12-alpine@sha256:e6dae589c1c05976188fd3bd019afd091445fc533ed2ea29001beddc7368a9c8
SECRET_DIR=$SECRET_ROOT
MASTER_PORT=$MASTER_PORT
SLAVE_PORT=$SLAVE_PORT
EDGE_SUBNET=$EDGE_SUBNET
EDGE_GATEWAY=$EDGE_GATEWAY
DATA_SUBNET=$DATA_SUBNET
NODE_PREFIX=$COMPOSE_PROJECT
OPS_ROOT=$OPS_ROOT
EOF
mv -f "$IMAGES_ENV.tmp" "$IMAGES_ENV"
compose config -q || die "compose config invalid" 3

# --- nginx shared includes (never the public mode switch unless asked) -----
install -d -m 0755 "$NGINX_DIR"
python3 -I "$OPS_ROOT/scripts/generate-nginx.py" --contract "$OPS_ROOT/ROUTE_CONTRACT.json" \
  --mode maintenance --env "$TAUAPI_ENV" --out /dev/null --proxy-include-out "$NGINX_DIR/proxy-backend.conf"
if [[ ! -f $NGINX_DIR/upstream-backend.conf ]]; then
  "$OPS_ROOT/scripts/set-upstream.sh" both
fi
if [[ $NGINX_MODE != keep ]]; then
  "$OPS_ROOT/scripts/set-site-mode.sh" "$NGINX_MODE"
fi

# --- start in dependency order --------------------------------------------
compose up -d postgres redis
if [[ $TAUAPI_ENV == qa ]]; then compose up -d mock-upstream; fi
for svc in postgres redis; do
  for _ in $(seq 1 60); do
    [[ $(docker inspect -f '{{.State.Health.Status}}' "$(container_id $svc)") == healthy ]] && break
    sleep 2
  done
  [[ $(docker inspect -f '{{.State.Health.Status}}' "$(container_id $svc)") == healthy ]] || die "$svc not healthy" 6
done
log "postgres and redis healthy"

compose up -d --no-deps backend-master
wait_status_ok "http://$MASTER_ADDR/api/status" 180 || die "backend-master not ready" 6
log "backend-master ready on $MASTER_ADDR"

if [[ $WITH_SLAVE == 1 ]]; then
  # Upstream computes the setup state once at process start (constant.Setup).
  # A slave started before admin initialisation keeps reporting
  # status=false and makes the SPA bounce between / and /setup, so it may
  # only start once the database is initialised.
  if ! curl -fsS --max-time 5 "http://$MASTER_ADDR/api/setup" | jq -e '.data.status == true' >/dev/null; then
    die "database not initialised yet: run bootstrap-admin.py, restart backend-master, then rerun with --with-slave" 3
  fi
  compose up -d --no-deps backend-slave
  wait_status_ok "http://$SLAVE_ADDR/api/status" 180 || die "backend-slave not ready" 6
  log "backend-slave ready on $SLAVE_ADDR"
fi
compose ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'
