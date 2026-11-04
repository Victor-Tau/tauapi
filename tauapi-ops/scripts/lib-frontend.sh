#!/usr/bin/env bash
# Shared frontend release helpers (sourced by deploy-frontend.sh / rollback-frontend.sh).
# shellcheck shell=bash

FE_HISTORY=$STATE_DIR/frontend-history   # one release id per line, newest last
FE_LOG=$STATE_DIR/frontend-releases.log

# Snapshot backend container ids + start times so we can prove a frontend
# release never restarted the backend.
backend_fingerprint() {
  local svc cid
  for svc in backend-master backend-slave; do
    cid=$(container_id "$svc")
    if [[ -n $cid ]]; then
      printf '%s %s %s\n' "$svc" "${cid:0:12}" "$(docker inspect -f '{{.State.StartedAt}}' "$cid")"
    else
      printf '%s absent\n' "$svc"
    fi
  done
}

# Verify the immutable public copy of a release matches its SHA256SUMS.
verify_public_assets() { # release_id
  local id=$1 rel=$FRONTEND_RELEASES/$1 pub=$PUBLIC_ROOT/_ui/$1
  [[ -f $rel/SHA256SUMS && -d $pub ]] || return 1
  ( cd "$pub" && grep -vE '  \./(index\.html|ui-version\.json|release-manifest\.json)$' "$rel/SHA256SUMS" | sha256sum -c --quiet - ) >/dev/null
}

# Atomically point current/frontend at a release (same filesystem rename).
switch_current() { # release_id
  local id=$1 tmp
  [[ -d $FRONTEND_RELEASES/$id ]] || return 1
  install -d -m 0755 "$(dirname "$FRONTEND_CURRENT")"
  tmp="$(dirname "$FRONTEND_CURRENT")/.frontend.$$"
  ln -sfn "$FRONTEND_RELEASES/$id" "$tmp"
  mv -Tf "$tmp" "$FRONTEND_CURRENT"
}

current_release() {
  local t
  t=$(readlink "$FRONTEND_CURRENT" 2>/dev/null) || return 0
  basename "$t"
}

# Smoke checks through the real Nginx + TLS on loopback.
# Args: release_id. Returns non-zero on the first failure.
verify_frontend_live() {
  local id=$1 base="$TAUAPI_ORIGIN" r=("${CURL_RESOLVE[@]}" -s --max-time 15)
  local body ct code js css
  for path in / /sign-in /dashboard /dashboard/overview /system-settings/site/system-info /oauth/github /user/reset /pricing; do
    body=$(curl "${r[@]}" -w '\n%{http_code} %{content_type}' "$base$path") || return 1
    code=$(tail -n1 <<<"$body")
    [[ $code == "200 text/html"* ]] || { log "page $path -> $code"; return 1; }
    grep -q "/_ui/$id/" <<<"$body" || { log "page $path does not reference release $id"; return 1; }
  done
  js=$(grep -oE "/_ui/$id/static/js/index\.[a-f0-9]+\.js" "$FRONTEND_RELEASES/$id/index.html" | head -1)
  css=$(grep -oE "/_ui/$id/static/css/index\.[a-f0-9]+\.css" "$FRONTEND_RELEASES/$id/index.html" | head -1)
  ct=$(curl "${r[@]}" -o /dev/null -w '%{http_code} %{content_type}' "$base$js")
  [[ $ct == "200 application/javascript"* || $ct == "200 text/javascript"* ]] || { log "js $js -> $ct"; return 1; }
  ct=$(curl "${r[@]}" -o /dev/null -w '%{http_code} %{content_type}' "$base$css")
  [[ $ct == "200 text/css"* ]] || { log "css $css -> $ct"; return 1; }
  # A lazily loaded chunk (dynamic import) must also be served.
  local async
  async=$(cd "$FRONTEND_RELEASES/$id" && find static/js/async -name '*.js' | head -1)
  ct=$(curl "${r[@]}" -o /dev/null -w '%{http_code}' "$base/_ui/$id/$async")
  [[ $ct == 200 ]] || { log "async chunk -> $ct"; return 1; }
  ct=$(curl "${r[@]}" -o /dev/null -w '%{http_code}' "$base/_ui/$id/static/js/does-not-exist.js")
  [[ $ct == 404 ]] || { log "missing asset -> $ct (expected 404)"; return 1; }
  body=$(curl "${r[@]}" "$base/_meta/ui-version.json")
  [[ $(jq -r .release_id <<<"$body") == "$id" ]] || { log "ui-version.json mismatch"; return 1; }
  ct=$(curl "${r[@]}" -o /dev/null -w '%{http_code} %{content_type}' "$base/api/status")
  [[ $ct == "200 application/json"* ]] || { log "/api/status -> $ct"; return 1; }
  ct=$(curl "${r[@]}" -o /dev/null -w '%{http_code} %{content_type}' "$base/api/does-not-exist")
  [[ $ct == "404 application/json"* ]] || { log "/api 404 -> $ct"; return 1; }
  return 0
}

record_release() { # action release_id previous
  install -d -m 0750 "$STATE_DIR"
  printf '%s %s %s prev=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" "${3:-none}" >> "$FE_LOG"
}
