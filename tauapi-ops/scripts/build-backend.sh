#!/usr/bin/env bash
# Build the API-only backend image from a committed backend revision.
# The build context is `git archive <rev>:tauapi-be` of the TauAPI monorepo, so
# only the committed backend subtree is used: no frontend, ops or uncommitted files.
#
# Usage: build-backend.sh [--repo /opt/tauapi] [--subdir tauapi-be] [--rev main] [--tag <tag>]
# Output: prints KEY=VALUE lines (BACKEND_COMMIT, IMAGE_TAG, IMAGE_ID) and writes
#         /srv/tauapi/artifacts/backend/<tag>.json
# Exit codes: 0 ok, 2 usage, 3 dirty/invalid revision, 4 build failure.
set -euo pipefail

REPO=/opt/tauapi
SUBDIR=tauapi-be
REV=main
TAG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --subdir) SUBDIR="$2"; shift 2 ;;
    --rev) REV="$2"; shift 2 ;;
    --tag) TAG="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

DOCKER=(docker)
if ! docker info >/dev/null 2>&1; then DOCKER=(sudo -A docker); fi

COMMIT=$(git -C "$REPO" rev-parse --verify "$REV^{commit}") || exit 3
SHORT=${COMMIT:0:12}
VERSION=$(git -C "$REPO" show "$COMMIT:$SUBDIR/VERSION" 2>/dev/null | tr -d '[:space:]')
[[ -n "$VERSION" ]] || VERSION="0.0.0"
[[ -n "$TAG" ]] || TAG="tauapi-be:${SHORT}"
UPSTREAM=$(git -C "$REPO" show "$COMMIT:$SUBDIR/UPSTREAM.json" | python3 -I -c 'import json,sys;print(json.load(sys.stdin)["upstream_commit"])')

WORK=$(mktemp -d /tmp/tauapi-be-build.XXXXXX)
trap 'rm -rf "$WORK"' EXIT
git -C "$REPO" archive --format=tar "$COMMIT:$SUBDIR" | tar -x -C "$WORK"
# Version shown by the app: upstream VERSION file plus our backend commit.
printf '%s+be.%s\n' "${VERSION:-dev}" "$SHORT" > "$WORK/VERSION"
if [[ -e "$WORK/web" || -e "$WORK/electron" ]]; then
  echo "backend context unexpectedly contains web/ or electron/" >&2; exit 3
fi

echo "building $TAG from $COMMIT" >&2
if ! "${DOCKER[@]}" build --pull=false \
    --label "org.opencontainers.image.revision=$COMMIT" \
    --label "org.opencontainers.image.source=local:/opt/tauapi (tauapi-be/)" \
    --label "tauapi.upstream.commit=$UPSTREAM" \
    --label "tauapi.component=backend" \
    -t "$TAG" "$WORK" >&2; then
  exit 4
fi
IMAGE_ID=$("${DOCKER[@]}" image inspect --format '{{.Id}}' "$TAG")

# The runtime image must not carry application test sources or frontend output.
if "${DOCKER[@]}" run --rm --entrypoint /bin/sh "$TAG" -c 'find / -xdev \( -name index.html -o -path "*/web/dist*" -o -name "*_test.go" -o -name "*.test.*" -o -name "*.spec.*" -o -name "test_*.py" -o -path "/tests/*" -o -path "/testdata/*" -o -path "/qa/*" \) 2>/dev/null | grep -v "^/usr/share" | head -1' | grep -q .; then
  echo "backend image contains frontend or test artefacts" >&2; exit 4
fi

OUT=/srv/tauapi/artifacts/backend
mkdir -p "$OUT"
cat > "$OUT/${SHORT}.json" <<JSON
{
  "component": "backend",
  "backend_commit": "$COMMIT",
  "upstream_commit": "$UPSTREAM",
  "app_version": "${VERSION}+be.${SHORT}",
  "image_tag": "$TAG",
  "image_id": "$IMAGE_ID",
  "built_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON
echo "BACKEND_COMMIT=$COMMIT"
echo "IMAGE_TAG=$TAG"
echo "IMAGE_ID=$IMAGE_ID"
