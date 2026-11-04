#!/usr/bin/env bash
# Write the active backend upstream set and reload Nginx (validated).
# Usage: sudo set-upstream.sh both|master|slave
# A removed instance stops receiving NEW requests; in-flight requests on
# existing connections finish (Nginx reload keeps old workers until done).
source "$(dirname "$0")/lib.sh"
require_root
case "${1:-}" in
  both)   servers="    server $MASTER_ADDR max_fails=1 fail_timeout=5s;
    server $SLAVE_ADDR max_fails=1 fail_timeout=5s;" ;;
  master) servers="    server $MASTER_ADDR;" ;;
  slave)  servers="    server $SLAVE_ADDR;" ;;
  *) die "usage: set-upstream.sh both|master|slave" 2 ;;
esac
install -d -m 0755 "$NGINX_DIR"
target=$NGINX_DIR/upstream-backend.conf
[[ -f $target ]] && cp -p "$target" "$target.prev"
cat > "$target.tmp" <<CONF
# Managed by set-upstream.sh (active set: $1)
upstream newapi_backend {
$servers
    keepalive 16;
}
CONF
mv -f "$target.tmp" "$target"
if [[ -f $NGINX_SITE ]] && [[ -L /etc/nginx/sites-enabled/newapi.conf ]]; then
  if ! nginx_reload_checked; then
    [[ -f $target.prev ]] && mv -f "$target.prev" "$target"
    die "nginx -t failed; upstream restored" 7
  fi
fi
mkdir -p "$STATE_DIR"; echo "$1" > "$STATE_DIR/active-upstream"
log "active upstream: $1"
