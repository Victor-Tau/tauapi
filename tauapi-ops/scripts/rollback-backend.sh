#!/usr/bin/env bash
# Roll both backend instances back to the previously recorded image, using the
# same drained one-at-a-time procedure. Refuses when the release record says a
# schema-changing migration happened (database restore is NOT an app rollback).
# Usage: sudo rollback-backend.sh [--allow-schema-change-reviewed]
source "$(dirname "$0")/lib.sh"
require_root
ST=$STATE_DIR/backend-release.json
[[ -f $ST ]] || die "no backend release recorded" 3
if [[ $(jq -r '.schema_changed // false' "$ST") == true && ${1:-} != --allow-schema-change-reviewed ]]; then
  die "last release changed the schema; verify the old image can read it, then rerun with --allow-schema-change-reviewed" 3
fi
exec "$(dirname "$0")/deploy-backend.sh" --rollback --skip-backup
