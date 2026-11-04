# Shared helpers for tauapi ops scripts. Source, do not execute.
# shellcheck shell=bash
set -euo pipefail
umask 027

TAUAPI_ENV=${TAUAPI_ENV:-prod}
TAUAPI_DOMAIN=api.victor-tau.xyz
OPS_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
case "$TAUAPI_ENV" in
  prod)
    TAUAPI_HTTPS_PORT=443
    SUFFIX=""
    MASTER_PORT=3001; SLAVE_PORT=3002
    EDGE_SUBNET=172.30.70.0/24; EDGE_GATEWAY=172.30.70.1; DATA_SUBNET=172.30.71.0/24
    ;;
  qa)
    # Isolated QA: own DB/Redis/volumes/secrets/ports, loopback-only HTTPS :8443
    # with the real certificate. Never shares state with production.
    TAUAPI_HTTPS_PORT=8443
    SUFFIX="-qa"
    MASTER_PORT=3101; SLAVE_PORT=3102
    EDGE_SUBNET=172.30.72.0/24; EDGE_GATEWAY=172.30.72.1; DATA_SUBNET=172.30.73.0/24
    ;;
  *) echo "unknown TAUAPI_ENV=$TAUAPI_ENV" >&2; exit 2 ;;
esac
if [[ $TAUAPI_HTTPS_PORT == 443 ]]; then
  TAUAPI_ORIGIN=https://$TAUAPI_DOMAIN
else
  TAUAPI_ORIGIN=https://$TAUAPI_DOMAIN:$TAUAPI_HTTPS_PORT
fi
SECRET_ROOT=/etc/tauapi$SUFFIX
RUNTIME_ROOT=/srv/tauapi$SUFFIX
STACK_DIR=$RUNTIME_ROOT/stack
STATE_DIR=$RUNTIME_ROOT/state
ARTIFACT_ROOT=/srv/tauapi/artifacts        # artefacts are shared, immutable inputs
FRONTEND_RELEASES=$RUNTIME_ROOT/releases/frontend
FRONTEND_CURRENT=$RUNTIME_ROOT/current/frontend
PUBLIC_ROOT=$RUNTIME_ROOT/public
BACKUP_ROOT=/var/backups/tauapi$SUFFIX
NGINX_DIR=/etc/nginx/tauapi$SUFFIX
NGINX_SITE=/etc/nginx/sites-available/tauapi$SUFFIX.conf
DEPLOY_LOCK=/run/lock/tauapi$SUFFIX-deploy.lock
COMPOSE_PROJECT=tauapi$SUFFIX
COMPOSE_FILE=$STACK_DIR/compose.yml
IMAGES_ENV=$STACK_DIR/images.env
MASTER_ADDR=127.0.0.1:$MASTER_PORT
SLAVE_ADDR=127.0.0.1:$SLAVE_PORT
CURL_RESOLVE=(--resolve "$TAUAPI_DOMAIN:$TAUAPI_HTTPS_PORT:127.0.0.1")
export TAUAPI_ENV

log() { printf '[%s] %s\n' "$(date -u +%H:%M:%S)" "$*" >&2; }
die() { local code=${2:-1}; log "ERROR: $1"; exit "$code"; }

require_root() {
  [[ $EUID -eq 0 ]] || die "run as root: sudo $0 $*" 2
}

compose() {
  local profile=()
  [[ $TAUAPI_ENV == qa ]] && profile=(--profile qa)
  docker compose -p "$COMPOSE_PROJECT" -f "$COMPOSE_FILE" --env-file "$IMAGES_ENV" "${profile[@]}" "$@"
}

# Global deploy lock. Top-level release/rollback/state-changing scripts call
# acquire_lock; child scripts inherit it through TAUAPI_LOCK_HELD=1 and never
# wait on the same lock again.
acquire_lock() {
  if [[ "${TAUAPI_LOCK_HELD:-0}" == 1 ]]; then return 0; fi
  local wait=${TAUAPI_LOCK_WAIT:-120}
  exec 9>"$DEPLOY_LOCK"
  if ! flock -w "$wait" 9; then
    die "deploy lock $DEPLOY_LOCK busy after ${wait}s (another deploy running?)" 9
  fi
  export TAUAPI_LOCK_HELD=1
}

# Wait for a URL to return JSON success:true. Args: url timeout_seconds
wait_status_ok() {
  local url=$1 timeout=${2:-120} start
  start=$(date +%s)
  while (( $(date +%s) - start < timeout )); do
    if curl -fsS --max-time 5 "$url" 2>/dev/null | jq -e '.success == true' >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

# Established TCP connections from Nginx to a local backend port.
backend_conn_count() {
  local port=$1
  ss -Htn state established "( dport = :$port )" 2>/dev/null | grep -c . || true
}

nginx_reload_checked() {
  nginx -t -q || return 1
  systemctl reload nginx
}

container_id() { compose ps -q "$1" 2>/dev/null || true; }

# json_get FILE KEY  -> top-level string value
json_get() { jq -r --arg k "$2" '.[$k] // empty' "$1"; }

# Annotated release tag in a source repo, created as the repo owner (the
# deploy scripts run as root). Idempotent: an existing tag on the same commit
# is accepted; a tag pointing elsewhere is reported, never moved.
tag_release() { # repo tag commit message
  local repo=$1 tag=$2 commit=$3 msg=$4 owner existing
  git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || return 0
  owner=$(stat -c %U "$repo")
  git -C "$repo" cat-file -e "$commit^{commit}" 2>/dev/null || { log "tag $tag: commit $commit not in $repo"; return 0; }
  existing=$(sudo -u "$owner" git -C "$repo" rev-parse -q --verify "refs/tags/$tag^{commit}" 2>/dev/null || true)
  if [[ -n $existing ]]; then
    [[ $existing == "$commit" ]] || log "WARNING: tag $tag already points to ${existing:0:12}, not moving it"
    return 0
  fi
  sudo -u "$owner" git -C "$repo" tag -a "$tag" "$commit" -m "$msg"
  sudo -u "$owner" git -C "$repo" push -q origin "refs/tags/$tag" 2>/dev/null || true
  log "tagged $repo $tag -> ${commit:0:12}"
}
