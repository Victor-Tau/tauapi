#!/usr/bin/env bash
# Publish a built frontend artefact and atomically switch current/frontend.
# Never restarts Nginx (reload only if the route contract changed) and never
# touches backend containers.
#
# Usage: sudo deploy-frontend.sh <release-id> [--artifacts /srv/tauapi/artifacts/frontend] [--no-verify]
# Exit codes: 0 ok, 2 usage, 3 artefact invalid, 7 nginx, 8 verification failed (rolled back), 9 lock.
source "$(dirname "$0")/lib.sh"
source "$(dirname "$0")/lib-frontend.sh"
require_root
ID=${1:-}; shift || true
ART=$ARTIFACT_ROOT/frontend
VERIFY=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifacts) ART="$2"; shift 2 ;;
    --no-verify) VERIFY=0; shift ;;
    *) die "unknown argument $1" 2 ;;
  esac
done
[[ $ID =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] || die "usage: deploy-frontend.sh <release-id>" 2
acquire_lock

TAR=$ART/$ID.tar.gz
[[ -f $TAR && -f $TAR.sha256 ]] || die "artefact $TAR (+.sha256) missing" 3
( cd "$ART" && sha256sum -c --quiet "$ID.tar.gz.sha256" ) || die "artefact checksum mismatch" 3

# 1) unpack into a temp dir and validate structure / paths
TMP=$(mktemp -d "$FRONTEND_RELEASES/.incoming.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
if tar -tzf "$TAR" | grep -E '(^/|(^|/)\.\.(/|$))' >/dev/null; then die "artefact contains unsafe paths" 3; fi
if tar -tvzf "$TAR" | grep -E '^[lhcbp]' >/dev/null; then die "artefact contains links/devices" 3; fi
tar -xzf "$TAR" -C "$TMP" --no-same-owner --no-same-permissions
for f in index.html ui-version.json release-manifest.json SHA256SUMS; do [[ -f $TMP/$f ]] || die "artefact missing $f" 3; done
( cd "$TMP" && sha256sum -c --quiet SHA256SUMS ) || die "artefact content checksum mismatch" 3
[[ $(jq -r .release_id "$TMP/release-manifest.json") == "$ID" ]] || die "manifest release_id mismatch" 3
[[ $(jq -r .asset_prefix "$TMP/release-manifest.json") == "/_ui/$ID/" ]] || die "asset prefix mismatch" 3
# every /_ui/<id>/ reference in index.html must exist in the artefact
while read -r ref; do
  [[ -f $TMP/${ref#/_ui/$ID/} ]] || die "index.html references missing $ref" 3
done < <(grep -oE "/_ui/$ID/[^\"' )]+" "$TMP/index.html" | sort -u)
# backend compatibility (manifest says which backend builds it was built against)
log "release $ID compatible_backend=$(jq -r .compatible_backend "$TMP/release-manifest.json") running=$(curl -s --max-time 5 http://$MASTER_ADDR/api/status | jq -r '.data.version // "unknown"')"

BEFORE_BACKEND=$(backend_fingerprint)
PREV=$(current_release)

# 2) immutable versioned assets first (never overwrite different bytes)
PUB=$PUBLIC_ROOT/_ui/$ID
if [[ -d $PUB ]]; then
  ( cd "$PUB" && grep -vE '  \./(index\.html|ui-version\.json|release-manifest\.json|SHA256SUMS)$' "$TMP/SHA256SUMS" | sha256sum -c --quiet - ) \
    || die "/_ui/$ID already exists with different bytes; refusing to overwrite" 3
  log "versioned assets for $ID already published (identical)"
else
  STAGE=$(mktemp -d "$PUBLIC_ROOT/_ui/.stage.XXXXXX")
  rsync -a --exclude=/index.html --exclude=/ui-version.json --exclude=/release-manifest.json --exclude=/SHA256SUMS "$TMP/" "$STAGE/"
  find "$STAGE" -type d -exec chmod 0755 {} + ; find "$STAGE" -type f -exec chmod 0444 {} +
  chmod 0755 "$STAGE"; mv -T "$STAGE" "$PUB"
  log "published /_ui/$ID ($(find "$PUB" -type f | wc -l) files)"
fi

# 3) full release directory
REL=$FRONTEND_RELEASES/$ID
if [[ -d $REL ]]; then
  cmp -s "$REL/SHA256SUMS" "$TMP/SHA256SUMS" || die "release dir $ID exists with different content" 3
else
  find "$TMP" -type d -exec chmod 0755 {} + ; find "$TMP" -type f -exec chmod 0644 {} +
  mv -T "$TMP" "$REL"; trap - EXIT
fi

# 4) route contract: regenerate entry rules only if they changed (compatible superset)
MODE=$(cat "$STATE_DIR/site-mode" 2>/dev/null || echo maintenance)
NEW=$(mktemp); python3 -I "$OPS_ROOT/scripts/generate-nginx.py" --contract "$OPS_ROOT/ROUTE_CONTRACT.json" --mode "$MODE" --out "$NEW"
if ! cmp -s "$NEW" "$NGINX_SITE"; then
  log "route contract changed: applying entry rules before switching"
  "$OPS_ROOT/scripts/set-site-mode.sh" "$MODE" || die "nginx update failed" 7
fi
rm -f "$NEW"

# 5) atomic switch
switch_current "$ID"
log "current/frontend -> $ID (previous: ${PREV:-none})"

# 6) verify, roll back on failure
if [[ $VERIFY == 1 ]] && ! verify_frontend_live "$ID"; then
  if [[ -n $PREV ]]; then switch_current "$PREV"; log "verification failed; current restored to $PREV"; fi
  record_release deploy-failed "$ID" "$PREV"
  exit 8
fi
AFTER_BACKEND=$(backend_fingerprint)
[[ $BEFORE_BACKEND == "$AFTER_BACKEND" ]] || log "WARNING: backend fingerprint changed during frontend deploy"
grep -qx "$ID" "$FE_HISTORY" 2>/dev/null || echo "$ID" >> "$FE_HISTORY"
record_release deploy "$ID" "$PREV"
printf 'backend unchanged: %s\n' "$([[ $BEFORE_BACKEND == "$AFTER_BACKEND" ]] && echo yes || echo NO)"
echo "$BEFORE_BACKEND"
