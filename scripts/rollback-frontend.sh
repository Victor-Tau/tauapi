#!/usr/bin/env bash
# Switch current/frontend back to an already-published, verified release.
# No rebuild; the old artefact and its /_ui/<id>/ assets are reused as-is.
# Usage: sudo rollback-frontend.sh [<release-id>]   (default: previous in history)
# Exit codes: 0 ok, 2 usage, 3 target invalid, 8 verification failed (restored), 9 lock.
source "$(dirname "$0")/lib.sh"
source "$(dirname "$0")/lib-frontend.sh"
require_root
acquire_lock
CUR=$(current_release)
TARGET=${1:-}
if [[ -z $TARGET ]]; then
  TARGET=$(grep -vx "$CUR" "$FE_HISTORY" 2>/dev/null | tail -n1 || true)
fi
[[ -n $TARGET ]] || die "no previous release to roll back to" 3
[[ $TARGET != "$CUR" ]] || die "$TARGET is already current" 3
[[ -d $FRONTEND_RELEASES/$TARGET ]] || die "release $TARGET not found" 3
verify_public_assets "$TARGET" || die "versioned assets for $TARGET missing or modified" 3
BEFORE_BACKEND=$(backend_fingerprint)
switch_current "$TARGET"
log "current/frontend -> $TARGET (was $CUR)"
if ! verify_frontend_live "$TARGET"; then
  switch_current "$CUR"; record_release rollback-failed "$TARGET" "$CUR"
  die "rollback verification failed; restored $CUR" 8
fi
AFTER_BACKEND=$(backend_fingerprint)
record_release rollback "$TARGET" "$CUR"
printf 'backend unchanged: %s\n' "$([[ $BEFORE_BACKEND == "$AFTER_BACKEND" ]] && echo yes || echo NO)"
