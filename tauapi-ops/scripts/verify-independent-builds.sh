#!/usr/bin/env bash
# Independent-build acceptance (GOAL §17.2) for the TauAPI monorepo: export
# ONE subtree (git archive main:tauapi-fe or main:tauapi-be) into an empty temp
# dir and build/test it there, so it cannot read the sibling directory.
#   frontend: no sibling backend dir, no Go needed
#   backend:  no web/, no Bun/Node on PATH, no placeholder HTML
# Usage: verify-independent-builds.sh [fe|be|all]   -> summary to stdout, logs in /tmp
set -uo pipefail
WHAT=${1:-all}
TOOLS=$HOME/.local/toolchains
REPO=${TAUAPI_REPO:-/opt/tauapi}
rc=0

if [[ $WHAT == fe || $WHAT == all ]]; then
  D=$(mktemp -d /tmp/indep-fe.XXXXXX); L=$D.log
  mkdir -p "$D/tauapi-fe"; git -C "$REPO" archive main:tauapi-fe | tar -x -C "$D/tauapi-fe"
  cd "$D/tauapi-fe"
  ls -a "$D" | grep -vE '^\.{1,2}$|^tauapi-fe$' && { echo "fe: unexpected sibling dirs"; rc=1; }
  # PATH without Go
  export PATH="$TOOLS/bun-linux-x64:/usr/bin:/bin"
  if command -v go >/dev/null; then echo "fe: go unexpectedly on PATH"; rc=1; fi
  {
    bun install --frozen-lockfile && bun run typecheck && bun run test && TAUAPI_RELEASE_ID=indep-check bun run build
  } > "$L" 2>&1
  r=$?
  grep -rlE '\.\./(backend|tauapi-be|plugins|pkg)/' src scripts rsbuild.config.ts vitest.config.ts 2>/dev/null | head -3 > "$D/xrefs"
  find dist -name '*.go' -o -name 'go.mod' | head -1 > "$D/leak"
  echo "fe: build+test exit=$r tests=$(grep -oE 'Tests +[0-9]+ passed' "$L" | tail -1) cross-repo-refs=$(wc -l < "$D/xrefs") backend-files-in-dist=$(wc -l < "$D/leak") log=$L"
  (( r == 0 )) || rc=1
  cd /; rm -rf "$D"
fi

if [[ $WHAT == be || $WHAT == all ]]; then
  D=$(mktemp -d /tmp/indep-be.XXXXXX); L=$D.log
  mkdir -p "$D/tauapi-be"; git -C "$REPO" archive main:tauapi-be | tar -x -C "$D/tauapi-be"
  cd "$D/tauapi-be"
  [[ -e web || -e electron ]] && { echo "be: web/ or electron/ present"; rc=1; }
  export PATH="$TOOLS/go/bin:/usr/bin:/bin" GOTOOLCHAIN=local GOWORK=off
  for b in bun node npm; do command -v $b >/dev/null && { echo "be: $b unexpectedly on PATH ($(command -v $b))"; }; done
  {
    go build -o /dev/null . && go vet ./router/ ./middleware/ && go test ./... \
      && (cd relaykit && go build ./... && go test ./...) && (cd tokenkit && go build ./... && go test ./...)
  } > "$L" 2>&1
  r=$?
  find . -name index.html -not -path './docs/*' | head -3 > "$D/html"
  echo "be: build+test exit=$r ok-pkgs=$(grep -c '^ok' "$L") fail=$(grep -c '^FAIL' "$L") html-files=$(wc -l < "$D/html") log=$L"
  (( r == 0 )) || rc=1
  cd /; rm -rf "$D"
fi
exit $rc
