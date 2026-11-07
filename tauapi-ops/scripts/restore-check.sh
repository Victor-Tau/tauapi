#!/usr/bin/env bash
# Restore the newest (or given) dump into an ISOLATED throwaway PostgreSQL
# container on a private network and verify key tables and application reads.
# Never touches the production database or its volume.
# Usage: sudo restore-check.sh [dump-file]
# Exit codes: 0 ok, 3 no dump / checksum, 4 restore or verification failed.
source "$(dirname "$0")/lib.sh"
require_root
# shellcheck disable=SC1090
source "$IMAGES_ENV"
DUMP=${1:-$(ls -1t "$BACKUP_ROOT"/db/tauapi-*.dump 2>/dev/null | head -1)}
[[ -f $DUMP ]] || die "no dump found" 3
if [[ -f $DUMP.b2 ]]; then
  ( cd "$(dirname "$DUMP")" && b2sum -c --quiet "$(basename "$DUMP").b2" ) || die "dump checksum mismatch" 3
fi
# Legacy dumps have no BLAKE2 checksum; pg_restore still validates their structure.
NAME=tauapi-restorecheck-$$
NET=tauapi-restorecheck-$$
PW=$(python3 -I -c 'import secrets;print(secrets.token_urlsafe(24))')
cleanup() { docker rm -f "$NAME" "$NAME-app" >/dev/null 2>&1 || true; docker network rm "$NET" >/dev/null 2>&1 || true; }
trap cleanup EXIT
docker network create --internal "$NET" >/dev/null
docker run -d --name "$NAME" --network "$NET" --tmpfs /var/lib/postgresql/data:rw,size=1g \
  -e POSTGRES_USER=tauapi -e POSTGRES_DB=tauapi -e POSTGRES_PASSWORD="$PW" "$POSTGRES_IMAGE" >/dev/null
for _ in $(seq 1 60); do docker exec "$NAME" pg_isready -U tauapi -d tauapi -h 127.0.0.1 >/dev/null 2>&1 && break; sleep 1; done
docker exec -i "$NAME" pg_restore -U tauapi -d tauapi --no-owner --exit-on-error < "$DUMP" || die "pg_restore failed" 4
q() { docker exec "$NAME" psql -U tauapi -d tauapi -Atc "$1"; }
TABLES=$(q "select count(*) from information_schema.tables where table_schema='public'")
USERS=$(q "select count(*) from users")
ROOTS=$(q "select count(*) from users where role=100")
SETUP=$(q "select count(*) from setups")
OPTS=$(q "select count(*) from options")
log "restored $(basename "$DUMP"): tables=$TABLES users=$USERS root_users=$ROOTS setups=$SETUP options=$OPTS"
(( TABLES > 10 && ROOTS >= 1 && SETUP >= 1 )) || die "restored data failed sanity checks" 4
# Application read: start the current backend image against the restored DB
# on the isolated network (no published ports, no Redis) and query it.
docker run -d --name "$NAME-app" --network "$NET" \
  -e SQL_DSN="postgresql://tauapi:$PW@$NAME:5432/tauapi?sslmode=disable" \
  -e NODE_TYPE=slave -e SESSION_SECRET=restorecheck-only-not-production -e TZ=Asia/Singapore \
  "$BACKEND_MASTER_IMAGE" >/dev/null
ok=0
for _ in $(seq 1 60); do
  if docker exec "$NAME-app" wget -qO- http://127.0.0.1:3000/api/setup 2>/dev/null | grep -q '"status":true'; then ok=1; break; fi
  sleep 2
done
(( ok == 1 )) || die "application could not read restored database" 4
ADDR=$(docker exec "$NAME-app" wget -qO- http://127.0.0.1:3000/api/status | python3 -I -c 'import json,sys;print(json.load(sys.stdin)["data"]["server_address"])')
log "application read OK on restored DB (setup.status=true, server_address=$ADDR)"
mkdir -p "$STATE_DIR"
printf '%s restore-check %s tables=%s users=%s root=%s setups=%s app_read=ok\n' "$(date -u +%FT%TZ)" "$(basename "$DUMP")" "$TABLES" "$USERS" "$ROOTS" "$SETUP" >> "$STATE_DIR/restore-checks.log"
echo "RESTORE_CHECK=ok"
