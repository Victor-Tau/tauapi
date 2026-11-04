#!/usr/bin/env bash
# Prune old frontend releases under the retention policy (GOAL §8.3):
#   keep at least the newest 5 published releases AND everything younger than
#   30 days; never prune the current release, the newest previous release
#   (rollback target) or any release passed with --keep.
# Default is a dry run; pass --apply to delete.
# Usage: sudo prune-frontend.sh [--apply] [--keep ID]...
source "$(dirname "$0")/lib.sh"
source "$(dirname "$0")/lib-frontend.sh"
require_root
APPLY=0; KEEP=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --keep) KEEP+=("$2"); shift 2 ;;
    *) die "unknown argument $1" 2 ;;
  esac
done
acquire_lock
MIN_KEEP=5; MIN_AGE_DAYS=30
CUR=$(current_release)
PREV=$(grep -vx "$CUR" "$FE_HISTORY" 2>/dev/null | tail -n1 || true)
mapfile -t RELS < <(ls -1t "$FRONTEND_RELEASES" 2>/dev/null | grep -v '^\.')
now=$(date +%s); i=0
for id in "${RELS[@]}"; do
  i=$((i+1))
  age=$(( (now - $(stat -c %Y "$FRONTEND_RELEASES/$id")) / 86400 ))
  reason=""
  (( i <= MIN_KEEP )) && reason="newest-$MIN_KEEP"
  (( age < MIN_AGE_DAYS )) && reason="${reason:+$reason,}younger-than-${MIN_AGE_DAYS}d"
  [[ $id == "$CUR" ]] && reason="${reason:+$reason,}current"
  [[ $id == "$PREV" ]] && reason="${reason:+$reason,}rollback-target"
  for k in "${KEEP[@]}"; do [[ $id == "$k" ]] && reason="${reason:+$reason,}pinned"; done
  if [[ -n $reason ]]; then
    printf 'keep   %-28s age=%sd (%s)\n' "$id" "$age" "$reason"
    continue
  fi
  printf 'prune  %-28s age=%sd\n' "$id" "$age"
  if [[ $APPLY == 1 ]]; then
    rm -rf --one-file-system "${FRONTEND_RELEASES:?}/$id" "${PUBLIC_ROOT:?}/_ui/$id"
    record_release prune "$id" "$CUR"
  fi
done
[[ $APPLY == 1 ]] || echo "(dry run; pass --apply to delete)"
