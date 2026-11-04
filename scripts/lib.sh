# Shared helpers for newapi-victor ops scripts. Source, do not execute.
# shellcheck shell=bash
set -euo pipefail
umask 027

NEWAPI_DOMAIN=api.victor-tau.xyz
NEWAPI_ORIGIN=https://api.victor-tau.xyz
OPS_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SECRET_ROOT=/etc/newapi
RUNTIME_ROOT=/srv/newapi
STACK_DIR=$RUNTIME_ROOT/stack
STATE_DIR=$RUNTIME_ROOT/state
ARTIFACT_ROOT=$RUNTIME_ROOT/artifacts
FRONTEND_RELEASES=$RUNTIME_ROOT/releases/frontend
FRONTEND_CURRENT=$RUNTIME_ROOT/current/frontend
PUBLIC_ROOT=$RUNTIME_ROOT/public
BACKUP_ROOT=/var/backups/newapi
NGINX_DIR=/etc/nginx/newapi
NGINX_SITE=/etc/nginx/sites-available/newapi.conf
DEPLOY_LOCK=/run/lock/newapi-deploy.lock
COMPOSE_PROJECT=newapi
COMPOSE_FILE=$STACK_DIR/compose.yml
IMAGES_ENV=$STACK_DIR/images.env
MASTER_ADDR=127.0.0.1:3001
SLAVE_ADDR=127.0.0.1:3002

log() { printf '[%s] %s\n' "$(date -u +%H:%M:%S)" "$*" >&2; }
die() { local code=${2:-1}; log "ERROR: $1"; exit "$code"; }

require_root() {
  [[ $EUID -eq 0 ]] || die "run as root: sudo $0 $*" 2
}

compose() {
  docker compose -p "$COMPOSE_PROJECT" -f "$COMPOSE_FILE" --env-file "$IMAGES_ENV" "$@"
}

# Global deploy lock. Top-level release/rollback/state-changing scripts call
# acquire_lock; child scripts inherit it through NEWAPI_LOCK_HELD=1 and never
# wait on the same lock again.
acquire_lock() {
  if [[ "${NEWAPI_LOCK_HELD:-0}" == 1 ]]; then return 0; fi
  local wait=${NEWAPI_LOCK_WAIT:-120}
  exec 9>"$DEPLOY_LOCK"
  if ! flock -w "$wait" 9; then
    die "deploy lock $DEPLOY_LOCK busy after ${wait}s (another deploy running?)" 9
  fi
  export NEWAPI_LOCK_HELD=1
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
