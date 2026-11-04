#!/usr/bin/env bash
# Reproducible upstream sync (never auto-deploys).
#   1. fetch a pinned upstream SHA/tag into the read-only cache
#   2. import it onto vendor/upstream of each split repo (linear; no-op if same)
#   3. create upgrade/<short-sha> from main and three-way merge vendor/upstream
#   4. leave the branch for build/test/contract review; main is never rewritten
#
# Usage: sync-upstream.sh <full-sha-or-tag> [--repos fe,be]
# Exit codes: 0 merged cleanly (review + test next), 2 usage, 3 fetch failed,
#             12 merge conflicts left on upgrade/<sha> for manual resolution.
set -euo pipefail
REF=${1:-}; shift || true
REPOS=fe,be
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repos) REPOS="$2"; shift 2 ;;
    *) echo "unknown argument $1" >&2; exit 2 ;;
  esac
done
[[ -n $REF ]] || { echo "usage: sync-upstream.sh <sha|tag>" >&2; exit 2; }
CACHE=/var/cache/tauapi/upstream
OPS=$(cd "$(dirname "$0")/.." && pwd)
git -C "$CACHE" fetch -q origin "$REF" || git -C "$CACHE" fetch -q origin "refs/tags/$REF:refs/tags/$REF" || exit 3
SHA=$(git -C "$CACHE" rev-parse --verify "FETCH_HEAD^{commit}" 2>/dev/null || git -C "$CACHE" rev-parse --verify "$REF^{commit}")
SHORT=${SHA:0:12}
status=0
for r in ${REPOS//,/ }; do
  kind=$([[ $r == fe ]] && echo frontend || echo backend)
  repo=/opt/tauapi/tauapi-$r
  python3 -I "$OPS/scripts/import-upstream.py" --upstream "$CACHE" --sha "$SHA" --kind "$kind" --repo "$repo"
  if [[ -n $(git -C "$repo" status --porcelain) ]]; then
    echo "$repo has uncommitted changes; skipping merge" >&2; status=12; continue
  fi
  branch=upgrade/$SHORT
  if git -C "$repo" rev-parse -q --verify "refs/heads/$branch" >/dev/null; then
    echo "$repo: $branch already exists (resume there)"; continue
  fi
  git -C "$repo" switch -q -c "$branch" main
  if git -C "$repo" merge --no-ff -m "Merge upstream $SHORT into $branch" vendor/upstream; then
    echo "$repo: merged vendor/upstream ($SHORT) into $branch"
  else
    echo "$repo: conflicts on $branch; resolve, then build/test before merging to main" >&2
    status=12
  fi
done
cat <<EOF
Next (manual gates, GOAL §6.6):
  - backend:  git -C /opt/tauapi/tauapi-be switch upgrade/$SHORT && go build . && go test ./... (relaykit/tokenkit too)
  - frontend: bun install --frozen-lockfile && bun run typecheck && bun run test && bun run build
  - compare testdata/contracts/frontend_simulation.json with backend pkg/billingexpr/testdata (UPSTREAM.json sha256)
  - review schema/auth/plugin route changes; regenerate ROUTE_CONTRACT.json if src/routes changed
  - only then merge upgrade/$SHORT into main and release with build-*/deploy-* scripts
EOF
exit $status
