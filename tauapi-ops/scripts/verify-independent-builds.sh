#!/usr/bin/env bash
# Independent-build acceptance (GOAL §17.2) for the TauAPI monorepo: export
# ONE subtree (git archive REV:tauapi-fe or REV:tauapi-be) into an empty temp
# dir and build/test it there, so it cannot read the sibling directory.
#   frontend: no sibling backend dir, no Go needed
#   backend:  no web/, no Bun/Node on PATH, no placeholder HTML
# Usage: verify-independent-builds.sh [fe|be|all]   -> summary to stdout, logs in /tmp
set -euo pipefail
WHAT=${1:-all}
case "$WHAT" in fe|be|all) ;; *) echo "Expected fe, be or all" >&2; exit 2 ;; esac
BUN_DIR=${TAUAPI_BUN_DIR:-$(dirname "$(command -v bun || true)")}
GO_DIR=${TAUAPI_GO_DIR:-$(dirname "$(command -v go || true)")}
REPO=${TAUAPI_REPO:-$(git -C "$(dirname "$0")" rev-parse --show-toplevel)}
REV=${TAUAPI_VERIFY_REV:-}
[[ -n "$REV" ]] || { echo "Set TAUAPI_VERIFY_REV to the exact candidate revision" >&2; exit 3; }
git -C "$REPO" rev-parse --verify "$REV^{commit}" >/dev/null || exit 3
rc=0

if [[ $WHAT == fe || $WHAT == all ]]; then
  D=$(mktemp -d /tmp/indep-fe.XXXXXX); L=$D.log
  mkdir -p "$D/tauapi-fe"; git -C "$REPO" archive "$REV:tauapi-fe" | tar -x -C "$D/tauapi-fe"
  cd "$D/tauapi-fe"
  ls -a "$D" | grep -vE '^\.{1,2}$|^tauapi-fe$' && { echo "fe: unexpected sibling dirs"; rc=1; }
  # PATH without Go
  export PATH="$BUN_DIR:/usr/bin:/bin"
  if command -v go >/dev/null; then echo "fe: go unexpectedly on PATH"; rc=1; fi
  set +e
  {
    bun install --frozen-lockfile && bun run typecheck && bun run test && TAUAPI_RELEASE_ID=indep-check bun run build
  } > "$L" 2>&1
  r=$?
  set -e
  (grep -rlE '\.\./(backend|tauapi-be|plugins|pkg)/' src scripts rsbuild.config.ts vitest.config.ts 2>/dev/null || true) | head -3 > "$D/xrefs"
  find dist -name '*.go' -o -name 'go.mod' | head -1 > "$D/leak"
  echo "fe: build+test exit=$r tests=$(grep -oE 'Tests +[0-9]+ passed' "$L" | tail -1 || true) cross-repo-refs=$(wc -l < "$D/xrefs") backend-files-in-dist=$(wc -l < "$D/leak") log=$L"
  (( r == 0 )) || rc=1
  cd /; rm -rf "$D"
fi

if [[ $WHAT == be || $WHAT == all ]]; then
  D=$(mktemp -d /tmp/indep-be.XXXXXX); L=$D.log
  mkdir -p "$D/tauapi-be"; git -C "$REPO" archive "$REV:tauapi-be" | tar -x -C "$D/tauapi-be"
  cd "$D/tauapi-be"
  [[ -e web || -e electron ]] && { echo "be: web/ or electron/ present"; rc=1; }
  # Curate system tools so the Go acceptance cannot discover a JS runtime.
  mkdir -p "$D/system-bin"
  for tool in /usr/bin/*; do
    name=${tool##*/}
    case "$name" in node|nodejs|npm|npx|bun|bunx|yarn|yarnpkg|pnpm|corepack|go) continue ;; esac
    [[ -x "$tool" && ! -d "$tool" ]] && ln -s "$tool" "$D/system-bin/$name"
  done
  export PATH="$GO_DIR:$D/system-bin" GOTOOLCHAIN=local GOWORK=off
  for b in bun node npm; do
    if command -v "$b" >/dev/null; then echo "be: forbidden JS runtime $b on PATH" >&2; exit 1; fi
  done
  set +e
  {
    go build -o /dev/null . && go vet ./router/ ./middleware/ && go test ./... \
      && (cd relaykit && go build ./... && go test ./...) && (cd tokenkit && go build ./... && go test ./...)
  } > "$L" 2>&1
  r=$?
  set -e
  find . -name index.html -not -path './docs/*' | head -3 > "$D/html"
  echo "be: build+test exit=$r ok-pkgs=$(grep -c '^ok' "$L" || true) fail=$(grep -c '^FAIL' "$L" || true) html-files=$(wc -l < "$D/html") log=$L"
  (( r == 0 )) || rc=1
  cd /; rm -rf "$D"
fi
exit $rc
