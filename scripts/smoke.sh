#!/usr/bin/env bash
# End-to-end smoke for the public entry (or QA with TAUAPI_ENV=qa):
# pages, API, assets, cache headers, routing contract, versions, auth.
# Usage: sudo smoke.sh [--public]      (--public: real public IP instead of loopback)
# Output: one line per check + summary; exit 0 only if all pass.
source "$(dirname "$0")/lib.sh"
PUBLIC=0; [[ ${1:-} == --public ]] && PUBLIC=1
R=(-s --max-time 15)
[[ $PUBLIC == 0 ]] && R+=("${CURL_RESOLVE[@]}")
B=$TAUAPI_ORIGIN
pass=0; failn=0
check() { # name expected actual
  if [[ $3 == $2 ]]; then printf '  ok    %-44s %s\n' "$1" "$3"; pass=$((pass+1))
  else printf '  FAIL  %-44s got=%s want=%s\n' "$1" "$3" "$2"; failn=$((failn+1)); fi
}
hc() { curl "${R[@]}" -o /dev/null -w '%{http_code} %{content_type}' "$B$1" | sed 's/; charset=utf-8//'; }
hdr() { curl "${R[@]}" -o /dev/null -w "%header{$2}" "$B$1"; }

REL=$(curl "${R[@]}" "$B/_meta/ui-version.json" | jq -r .release_id)
echo "== $TAUAPI_ENV $([[ $PUBLIC == 1 ]] && echo public || echo loopback) $B  frontend=$REL"
echo "-- SPA pages (HTML, no-store)"
for p in / /sign-in /login /console/token /oauth/github /user/reset /reset /dashboard/overview /usage-logs/common \
         /system-settings/billing/payment /keys /playground /pricing/x /chat/abc /setup /401; do
  check "page $p" "200 text/html" "$(hc "$p")"
done
check "entry cache-control" "no-cache, no-store, must-revalidate" "$(hdr / cache-control)"
echo "-- backend routes (JSON, never SPA)"
check "/api/status" "200 application/json" "$(hc /api/status)"
check "/api/unknown -> JSON 404" "404 application/json" "$(hc /api/__nope__)"
check "/v1/models (no key)" "401 application/json" "$(hc /v1/models)"
check "/v1beta/models (no key)" "401 application/json" "$(hc /v1beta/models)"
check "/pg/chat/completions GET" "404 application/json" "$(hc /pg/chat/completions)"
check "/mj/submit/imagine GET" "404 application/json" "$(hc /mj/submit/imagine)"
check "/fast/mj/... (mode mj) GET" "404 application/json" "$(hc /fast/mj/submit/imagine)"
check "/dashboard/billing/usage beats SPA" "401 application/json" "$(hc /dashboard/billing/usage)"
check "/dashboard/billing/subscription" "401 application/json" "$(hc /dashboard/billing/subscription)"
check "plugin /ali/api/v1/tasks/x" "401 application/json" "$(hc /ali/api/v1/tasks/x)"
check "plugin /tasks" "401 application/json" "$(hc /tasks)"
check "plugin /suno/fetch GET (POST-only)" "405" "$(curl "${R[@]}" -o /dev/null -w '%{http_code}' "$B/suno/fetch")"
check "unknown root path -> JSON 404" "404 application/json" "$(hc /no/such/thing)"
echo "-- assets"
JS=$(curl "${R[@]}" "$B/" | grep -oE "/_ui/$REL/static/js/index\.[a-f0-9]+\.js" | head -1)
check "entry js" "200 application/javascript" "$(hc "$JS")"
check "entry js immutable" "public, max-age=31536000, immutable" "$(hdr "$JS" cache-control)"
check "missing versioned asset" "404" "$(curl "${R[@]}" -o /dev/null -w '%{http_code}' "$B/_ui/$REL/static/js/missing.js")"
check "missing asset not cached" "" "$(hdr "/_ui/$REL/static/js/missing.js" cache-control)"
check "/logo.png revalidate" "no-cache" "$(hdr /logo.png cache-control)"
check "/_meta/ui-version.json" "200 application/json" "$(hc /_meta/ui-version.json)"
check "/.git/config hidden" "404" "$(curl "${R[@]}" -o /dev/null -w '%{http_code}' "$B/.git/config")"
check "/.env hidden" "404" "$(curl "${R[@]}" -o /dev/null -w '%{http_code}' "$B/.env")"
check "HSTS" "max-age=31536000" "$(hdr / strict-transport-security)"
if [[ $TAUAPI_ENV == prod ]]; then
  echo "-- http/tls"
  check "http -> https keeps path+query" "301 https://$TAUAPI_DOMAIN/pricing?a=1" \
    "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' --max-time 10 "http://$TAUAPI_DOMAIN/pricing?a=1")"
  check "tls verify (no -k)" "0" "$(curl "${R[@]}" -o /dev/null -w '%{ssl_verify_result}' "$B/")"
fi
echo "-- versions"
BV=$(curl "${R[@]}" "$B/api/status" | jq -r .data.version)
printf '  info  backend version %s, frontend release %s\n' "$BV" "$REL"
if [[ $EUID -eq 0 ]]; then
  echo "-- auth (login/refresh/logout)"
  args=(); [[ $PUBLIC == 1 ]] && args=(--public)
  if out=$(python3 -I "$OPS_ROOT/scripts/smoke-auth.py" "${args[@]}"); then
    check "auth session flow" "ok" "ok"
  else
    check "auth session flow" "ok" "$out"
  fi
fi
echo "== $pass passed, $failn failed"
[[ $failn == 0 ]]
