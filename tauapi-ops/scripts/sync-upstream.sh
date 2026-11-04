#!/usr/bin/env bash
# Reproducible upstream sync for the TauAPI monorepo (never auto-deploys).
#   1. fetch a pinned upstream SHA/tag into the read-only cache
#   2. import it onto vendor/upstream-fe and vendor/upstream-be (split layout at
#      branch root; linear; identical source+mapping => no-op)
#   3. create upgrade/<short-sha> from main and subtree-merge each import into
#      tauapi-fe/ and tauapi-be/ (three-way merge, customisations kept)
#   4. leave the branch for build/test/contract review; main is never rewritten
#
# Usage: sync-upstream.sh <full-sha-or-tag> [--parts fe,be]
# Exit codes: 0 merged cleanly (review + test next), 2 usage, 3 fetch failed,
#             12 merge conflicts / dirty tree, left for manual resolution.
set -euo pipefail
REF=${1:-}; shift || true
PARTS=fe,be
while [[ $# -gt 0 ]]; do
  case "$1" in
    --parts|--repos) PARTS="$2"; shift 2 ;;
    *) echo "unknown argument $1" >&2; exit 2 ;;
  esac
done
[[ -n $REF ]] || { echo "usage: sync-upstream.sh <sha|tag>" >&2; exit 2; }
CACHE=/var/cache/tauapi/upstream
ROOT=/opt/tauapi
OPS=$ROOT/tauapi-ops
git -C "$CACHE" fetch -q origin "$REF" || git -C "$CACHE" fetch -q origin "refs/tags/$REF:refs/tags/$REF" || exit 3
SHA=$(git -C "$CACHE" rev-parse --verify "FETCH_HEAD^{commit}" 2>/dev/null || git -C "$CACHE" rev-parse --verify "$REF^{commit}")
SHORT=${SHA:0:12}
[[ -z $(git -C "$ROOT" status --porcelain) ]] || { echo "$ROOT has uncommitted changes" >&2; exit 12; }
for p in ${PARTS//,/ }; do
  kind=$([[ $p == fe ]] && echo frontend || echo backend)
  python3 -I "$OPS/scripts/import-upstream.py" --upstream "$CACHE" --sha "$SHA" --kind "$kind" \
    --repo "$ROOT" --ref "vendor/upstream-$p"
done
branch=upgrade/$SHORT
if git -C "$ROOT" rev-parse -q --verify "refs/heads/$branch" >/dev/null; then
  echo "$branch already exists (resume there)"; exit 0
fi
start=$(git -C "$ROOT" symbolic-ref --short HEAD)
git -C "$ROOT" switch -q -c "$branch" main
status=0
for p in ${PARTS//,/ }; do
  if git -C "$ROOT" merge --no-ff -X "subtree=tauapi-$p/" -m "Merge upstream $SHORT into tauapi-$p/" "vendor/upstream-$p"; then
    echo "merged vendor/upstream-$p ($SHORT) into tauapi-$p/ on $branch"
  else
    echo "conflicts merging vendor/upstream-$p on $branch; resolve, commit, then continue" >&2
    status=12; break
  fi
done
[[ $status == 0 ]] && git -C "$ROOT" switch -q "$start"
cat <<EOT
Next (manual gates, GOAL §6.6), on branch $branch:
  - backend:  cd $ROOT/tauapi-be && go build . && go test ./... (relaykit/tokenkit too)
  - frontend: cd $ROOT/tauapi-fe && bun install --frozen-lockfile && bun run typecheck && bun run test && bun run build
  - compare tauapi-fe/testdata/contracts/frontend_simulation.json with tauapi-be/pkg/billingexpr/testdata (UPSTREAM.json sha256)
  - review schema/auth/plugin route changes; regenerate ROUTE_CONTRACT.json if src/routes changed
  - only then merge $branch into main and release with build-*/deploy-* scripts
EOT
exit $status
