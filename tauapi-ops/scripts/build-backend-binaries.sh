#!/usr/bin/env bash
# Build the linux-amd64 release archive from one committed backend subtree.
# Usage: build-backend-binaries.sh --rev REV --out DIRECTORY [--repo DIRECTORY]
# Run explicit tests for changed modules separately; no full suites are launched.
# This script never publishes or deploys.
set -euo pipefail
umask 022

REPO=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
REV=""
OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --rev) REV="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[[ -n $REV && -n $OUT ]] || { echo "--rev and --out are required" >&2; exit 2; }
COMMIT=$(git -C "$REPO" rev-parse --verify "$REV^{commit}")
SHORT=${COMMIT:0:12}
VERSION=$(git -C "$REPO" show "$COMMIT:tauapi-be/VERSION" | tr -d '[:space:]')
[[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "invalid VERSION" >&2; exit 2; }
mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)
[[ ! -e $OUT/tauapi-be-v${VERSION}-linux-amd64.tar.gz ]] || {
  echo "release archive already exists: amd64" >&2; exit 3;
}

WORK=$(mktemp -d /tmp/tauapi-be-binaries.XXXXXX)
trap 'rm -rf "$WORK"' EXIT
git -C "$REPO" archive "$COMMIT:tauapi-be" | tar -x -C "$WORK"
cd "$WORK"
[[ ! -e web && ! -e electron ]] || { echo "unexpected frontend sources" >&2; exit 3; }
export GOWORK=off GOTOOLCHAIN=local CGO_ENABLED=0
echo "== backend library builds: $COMMIT" >&2
for module in relaykit tokenkit; do
  (cd "$module" && go build ./...)
done
PGO=$(go list -m -f '{{.Dir}}' github.com/Calcium-Ion/moejs)/default.pgo
APP_VERSION="${VERSION}+be.${SHORT}"
arch=amd64
echo "== build linux/$arch" >&2
STAGE="$WORK/package-$arch"
mkdir "$STAGE"
GOOS=linux GOARCH="$arch" go build -trimpath -pgo="$PGO" \
  -ldflags "-s -w -X github.com/QuantumNous/new-api/common.Version=$APP_VERSION" \
  -o "$STAGE/new-api" .
cp LICENSE NOTICE THIRD-PARTY-LICENSES.md "$STAGE/"
python3 - "$STAGE/release-manifest.json" "$COMMIT" "$APP_VERSION" "$arch" <<'PY'
import datetime
import json
import subprocess
import sys
from pathlib import Path

path, commit, version, arch = sys.argv[1:]
manifest = {
    "component": "tauapi-be", "backend_commit": commit, "app_version": version,
    "upstream_commit": json.loads(Path("UPSTREAM.json").read_text())["upstream_commit"],
    "goos": "linux", "goarch": arch, "cgo_enabled": False,
    "toolchain": subprocess.check_output(["go", "version"], text=True).strip(),
    "schema_compatibility": "unknown",
    "built_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
}
Path(path).write_text(json.dumps(manifest, indent=2) + "\n")
PY
tar --owner=0 --group=0 --numeric-owner -czf "$OUT/tauapi-be-v${VERSION}-linux-${arch}.tar.gz" -C "$STAGE" .
echo "BACKEND_COMMIT=$COMMIT"
echo "BACKEND_VERSION=$APP_VERSION"
echo "ARTIFACTS=$OUT"
