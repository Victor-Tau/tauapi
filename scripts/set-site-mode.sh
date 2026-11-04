#!/usr/bin/env bash
# Switch the public site between maintenance (ACME + loopback only) and live.
# Usage: sudo set-site-mode.sh maintenance|live
source "$(dirname "$0")/lib.sh"
require_root
mode=${1:-}
[[ $mode == maintenance || $mode == live ]] || die "usage: set-site-mode.sh maintenance|live" 2
install -d -m 0755 "$NGINX_DIR"
[[ -f $NGINX_DIR/upstream-backend.conf ]] || "$OPS_ROOT/scripts/set-upstream.sh" both
backup=$(mktemp -d /tmp/tauapi-nginx-bak.XXXXXX)
# Back up only what this script touches.
[[ -f $NGINX_SITE ]] && cp -p "$NGINX_SITE" "$backup/tauapi.conf"
had_enabled=0; [[ -L /etc/nginx/sites-enabled/tauapi.conf ]] && had_enabled=1
had_bootstrap=0; [[ -L /etc/nginx/sites-enabled/tauapi-bootstrap.conf ]] && had_bootstrap=1
python3 -I "$OPS_ROOT/scripts/generate-nginx.py" --contract "$OPS_ROOT/ROUTE_CONTRACT.json" \
  --mode "$mode" --out "$NGINX_SITE.tmp" --proxy-include-out "$NGINX_DIR/proxy-backend.conf"
mv -f "$NGINX_SITE.tmp" "$NGINX_SITE"
ln -sfn "$NGINX_SITE" /etc/nginx/sites-enabled/tauapi.conf
rm -f /etc/nginx/sites-enabled/tauapi-bootstrap.conf
if ! nginx_reload_checked; then
  if [[ -f $backup/tauapi.conf ]]; then cp -p "$backup/tauapi.conf" "$NGINX_SITE"; else rm -f "$NGINX_SITE"; fi
  [[ $had_enabled == 1 ]] || rm -f /etc/nginx/sites-enabled/tauapi.conf
  [[ $had_bootstrap == 1 ]] && ln -sfn /etc/nginx/sites-available/tauapi-bootstrap.conf /etc/nginx/sites-enabled/tauapi-bootstrap.conf
  nginx -t -q && systemctl reload nginx
  die "nginx -t failed for mode=$mode; previous config restored" 7
fi
rm -rf "$backup"
mkdir -p "$STATE_DIR"; echo "$mode" > "$STATE_DIR/site-mode"
log "site mode: $mode"
