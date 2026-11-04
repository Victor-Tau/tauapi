#!/usr/bin/env bash
# Build a versioned static frontend artefact from a committed tauapi-fe revision.
#
# The source is `git archive <rev>:tauapi-fe` of the TauAPI monorepo into an
# empty temp dir (frontend subtree only: no backend/ops files, no uncommitted files). Dependencies are installed with the locked Bun
# version and --frozen-lockfile; typecheck and tests run before the build.
#
# Usage: build-frontend.sh [--repo /opt/tauapi] [--subdir tauapi-fe] [--rev main]
#                          [--release-id ID] [--skip-checks] [--compat-backend RANGE]
# Output: /srv/tauapi/artifacts/frontend/<release-id>.tar.gz (+ .sha256, manifest)
# Exit codes: 0 ok, 2 usage, 3 invalid revision / id exists, 4 check or build failure.
set -euo pipefail
umask 022

REPO=/opt/tauapi
SUBDIR=tauapi-fe
REV=main
RELEASE_ID=""
SKIP_CHECKS=0
COMPAT_BACKEND=">=be.53c0e999057f"
OUT=/srv/tauapi/artifacts/frontend
BUN_BIN=${BUN_BIN:-$HOME/.local/toolchains/bun-linux-x64/bun}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --subdir) SUBDIR="$2"; shift 2 ;;
    --rev) REV="$2"; shift 2 ;;
    --release-id) RELEASE_ID="$2"; shift 2 ;;
    --skip-checks) SKIP_CHECKS=1; shift ;;
    --compat-backend) COMPAT_BACKEND="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[[ -x $BUN_BIN ]] || { echo "bun not found at $BUN_BIN" >&2; exit 2; }
BUN_VERSION=$("$BUN_BIN" --version)

COMMIT=$(git -C "$REPO" rev-parse --verify "$REV^{commit}") || exit 3
SHORT=${COMMIT:0:12}
[[ -n $RELEASE_ID ]] || RELEASE_ID="$(date -u +%Y%m%d%H%M%S)-${SHORT:0:8}"
[[ $RELEASE_ID =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] || { echo "invalid release id" >&2; exit 2; }
mkdir -p "$OUT"
if [[ -e $OUT/$RELEASE_ID.tar.gz ]]; then echo "release id $RELEASE_ID already built" >&2; exit 3; fi
PM=$(git -C "$REPO" show "$COMMIT:$SUBDIR/package.json" | python3 -I -c 'import json,sys;print(json.load(sys.stdin).get("packageManager",""))')
[[ $PM == "bun@$BUN_VERSION" ]] || { echo "toolchain mismatch: package.json $PM vs bun $BUN_VERSION" >&2; exit 4; }
UPSTREAM=$(git -C "$REPO" show "$COMMIT:$SUBDIR/UPSTREAM.json" | python3 -I -c 'import json,sys;print(json.load(sys.stdin)["upstream_commit"])')
APP_VERSION="$(git -C "$REPO" show "$COMMIT:$SUBDIR/VERSION" | tr -d '[:space:]')"
[[ -n $APP_VERSION ]] || APP_VERSION=0.0.0
APP_VERSION="${APP_VERSION}+fe.${SHORT}"

WORK=$(mktemp -d /tmp/tauapi-fe-build.XXXXXX)
trap 'rm -rf "$WORK"' EXIT
git -C "$REPO" archive --format=tar "$COMMIT:$SUBDIR" | tar -x -C "$WORK/"
cd "$WORK"
echo "== install (frozen lockfile, bun $BUN_VERSION)" >&2
"$BUN_BIN" install --frozen-lockfile >&2 || exit 4
if [[ $SKIP_CHECKS == 0 ]]; then
  echo "== typecheck" >&2; "$BUN_BIN" run typecheck >&2 || exit 4
  echo "== test" >&2; "$BUN_BIN" run test >&2 || exit 4
fi
echo "== build release $RELEASE_ID" >&2
TAUAPI_RELEASE_ID="$RELEASE_ID" VITE_REACT_APP_VERSION="$APP_VERSION" NODE_OPTIONS=--max-old-space-size=2048 \
  "$BUN_BIN" run build >&2 || exit 4

DIST="$WORK/dist"
[[ -f $DIST/index.html ]] || { echo "dist/index.html missing" >&2; exit 4; }
grep -q "/_ui/$RELEASE_ID/" "$DIST/index.html" || { echo "index.html does not reference /_ui/$RELEASE_ID/" >&2; exit 4; }
# Artefact must not carry backend sources or secrets.
if find "$DIST" \( -name '*.go' -o -name '.env*' -o -name '*.pem' -o -name '*.key' -o -name 'go.mod' \) | grep -q .; then
  echo "dist contains backend/secret-like files" >&2; exit 4
fi

cat > "$DIST/ui-version.json" <<JSON
{
  "component": "tauapi-fe",
  "release_id": "$RELEASE_ID",
  "frontend_commit": "$COMMIT",
  "app_version": "$APP_VERSION",
  "asset_prefix": "/_ui/$RELEASE_ID/",
  "built_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON
ASSET_COUNT=$(find "$DIST" -type f ! -name index.html ! -name ui-version.json | wc -l)
cat > "$DIST/release-manifest.json" <<JSON
{
  "component": "tauapi-fe",
  "release_id": "$RELEASE_ID",
  "frontend_commit": "$COMMIT",
  "upstream_commit": "$UPSTREAM",
  "app_version": "$APP_VERSION",
  "asset_prefix": "/_ui/$RELEASE_ID/",
  "compatible_backend": "$COMPAT_BACKEND",
  "toolchain": {"bun": "$BUN_VERSION", "node_version_file": "$(cat .node-version 2>/dev/null)"},
  "file_count": $ASSET_COUNT,
  "built_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON
( cd "$DIST" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS )
tar --owner=0 --group=0 --numeric-owner -czf "$OUT/$RELEASE_ID.tar.gz" -C "$DIST" .
( cd "$OUT" && sha256sum "$RELEASE_ID.tar.gz" > "$RELEASE_ID.tar.gz.sha256" )
cp "$DIST/release-manifest.json" "$OUT/$RELEASE_ID.manifest.json"
echo "RELEASE_ID=$RELEASE_ID"
echo "FRONTEND_COMMIT=$COMMIT"
echo "ARTIFACT=$OUT/$RELEASE_ID.tar.gz"
echo "SHA256=$(cut -d' ' -f1 "$OUT/$RELEASE_ID.tar.gz.sha256")"
