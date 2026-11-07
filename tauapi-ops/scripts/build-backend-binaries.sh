#!/usr/bin/env bash
# Build portable Linux release archives from one committed backend subtree.
# Usage: build-backend-binaries.sh --rev REV --out DIRECTORY [--repo DIRECTORY]
# Checks run before packaging; this script never publishes or deploys.
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
for arch in amd64 arm64; do
  [[ ! -e $OUT/tauapi-be-v${VERSION}-linux-${arch}.tar.gz ]] || {
    echo "release archive already exists: $arch" >&2; exit 3;
  }
done

WORK=$(mktemp -d /tmp/tauapi-be-binaries.XXXXXX)
trap 'rm -rf "$WORK"' EXIT
git -C "$REPO" archive "$COMMIT:tauapi-be" | tar -x -C "$WORK"
cd "$WORK"
[[ ! -e web && ! -e electron ]] || { echo "unexpected frontend sources" >&2; exit 3; }
export GOWORK=off GOTOOLCHAIN=local CGO_ENABLED=0
echo "== backend vet and tests: $COMMIT" >&2
go vet ./router/ ./middleware/
go test -p 1 ./...
for module in relaykit tokenkit; do
  (cd "$module" && go build ./... && go test -p 1 ./...)
done
PGO=$(go list -m -f '{{.Dir}}' github.com/Calcium-Ion/moejs)/default.pgo
APP_VERSION="${VERSION}+be.${SHORT}"
for arch in amd64 arm64; do
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
  (cd "$STAGE" && sha256sum new-api LICENSE NOTICE THIRD-PARTY-LICENSES.md release-manifest.json > SHA256SUMS)
  tar --owner=0 --group=0 --numeric-owner -czf "$OUT/tauapi-be-v${VERSION}-linux-${arch}.tar.gz" -C "$STAGE" .
done
(cd "$OUT" && sha256sum "tauapi-be-v${VERSION}-linux-"*.tar.gz > checksums-linux.txt)
echo "BACKEND_COMMIT=$COMMIT"
echo "BACKEND_VERSION=$APP_VERSION"
echo "ARTIFACTS=$OUT"
