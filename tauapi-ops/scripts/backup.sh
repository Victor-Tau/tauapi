#!/usr/bin/env bash
# Consistent logical PostgreSQL backup (pg_dump -Fc from the running postgres
# container, same major version), Git bundles, release manifests and non-secret
# ops config. Retention: 7 daily + 4 weekly; never deletes the newest valid
# backup. Secrets/certificates are NOT included (separate protected policy).
#
# Usage: sudo backup.sh [--reason TEXT] [--no-prune]
# Exit codes: 0 ok, 3 dump failed/invalid, 11 low disk (backup kept, warning).
source "$(dirname "$0")/lib.sh"
require_root
REASON=scheduled
PRUNE=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --reason) REASON="$2"; shift 2 ;;
    --no-prune) PRUNE=0; shift ;;
    *) die "unknown argument $1" 2 ;;
  esac
done
umask 077
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
DB_DIR=$BACKUP_ROOT/db; GIT_DIR_B=$BACKUP_ROOT/git; META_DIR=$BACKUP_ROOT/meta
install -d -m 0700 "$BACKUP_ROOT" "$DB_DIR" "$GIT_DIR_B" "$META_DIR"

PG=$(container_id postgres)
[[ -n $PG ]] || die "postgres container not running" 3
DUMP=$DB_DIR/tauapi-$STAMP.dump
docker exec "$PG" pg_dump -U tauapi -d tauapi -Fc --no-owner > "$DUMP.part" || { rm -f "$DUMP.part"; die "pg_dump failed" 3; }
docker exec -i "$PG" pg_restore --list < "$DUMP.part" > /dev/null || { rm -f "$DUMP.part"; die "dump not readable by pg_restore" 3; }
mv "$DUMP.part" "$DUMP"
b2sum "$DUMP" > "$DUMP.b2"
PGVER=$(docker exec "$PG" psql -U tauapi -d tauapi -Atc 'show server_version')
printf '{"file":"%s","reason":"%s","pg_server_version":"%s","bytes":%s,"at":"%s"}\n' \
  "$(basename "$DUMP")" "$REASON" "$PGVER" "$(stat -c %s "$DUMP")" "$STAMP" > "$DUMP.json"
log "db backup $(basename "$DUMP") ($(du -h "$DUMP" | cut -f1), pg $PGVER, reason=$REASON)"

# Git bundle (all refs) of the TauAPI monorepo.
for repo in tauapi; do
  src=/var/lib/tauapi/git/$repo.git
  [[ -d $src ]] || continue
  b=$GIT_DIR_B/$repo-$STAMP.bundle
  git -C "$src" bundle create "$b" --all >/dev/null 2>&1 && git -C "$src" bundle verify "$b" >/dev/null 2>&1 \
    || { rm -f "$b"; log "WARNING: bundle for $repo failed"; continue; }
done
# Release manifests and non-secret ops state.
tar -C "$RUNTIME_ROOT" -czf "$META_DIR/meta-$STAMP.tar.gz" \
  --exclude='releases/frontend/*/static' artifacts/backend artifacts/frontend/*.manifest.json state stack/images.env 2>/dev/null || true

prune() { # dir pattern
  local dir=$1 pat=$2 keep_daily=7 keep_weekly=4
  mapfile -t files < <(ls -1t "$dir"/$pat 2>/dev/null)
  (( ${#files[@]} > 1 )) || return 0
  declare -A keep=() days=() weeks=()
  keep[${files[0]}]=1
  for f in "${files[@]}"; do
    local d w; d=$(date -u -r "$f" +%F); w=$(date -u -r "$f" +%G-%V)
    if [[ -z ${days[$d]:-} && ${#days[@]} -lt $keep_daily ]]; then days[$d]=1; keep[$f]=1; fi
    if [[ -z ${weeks[$w]:-} && ${#weeks[@]} -lt $keep_weekly ]]; then weeks[$w]=1; keep[$f]=1; fi
  done
  for f in "${files[@]}"; do
    [[ -n ${keep[$f]:-} ]] && continue
    rm -f "$f" "$f.b2" "$f.json"
  done
}
if [[ $PRUNE == 1 ]]; then
  prune "$DB_DIR" 'tauapi-*.dump'
  prune "$GIT_DIR_B" "tauapi-2*.bundle"
  prune "$META_DIR" 'meta-*.tar.gz'
fi
avail=$(df --output=avail -k "$BACKUP_ROOT" | tail -1)
if (( avail < 2*1024*1024 )); then log "WARNING: less than 2 GiB free under $BACKUP_ROOT"; exit 11; fi
echo "BACKUP=$DUMP"
