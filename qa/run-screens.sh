#!/usr/bin/env bash
# Run the visual-review screenshot pass against the isolated QA site.
# Credentials are read from /etc/tauapi-qa (root-only) and handed to the
# browser process through its environment only (never argv, never disk).
# Usage: sudo run-screens.sh <out-dir> [filter]
set -euo pipefail
OUT=${1:?out dir}; FILTER=${2:-}
OPS=$(cd "$(dirname "$0")/.." && pwd)
PW=/home/tau/tools-setup/pw/node_modules/playwright-core
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 2; }
QA_ADMIN_USER=$(jq -r .username /etc/tauapi-qa/initial-admin.json)
QA_ADMIN_PASS=$(jq -r .password /etc/tauapi-qa/initial-admin.json)
QA_USER=$(jq -r .username /etc/tauapi-qa/qa-user.json)
QA_USER_PASS=$(jq -r .password /etc/tauapi-qa/qa-user.json)
install -d -o tau -g tau "$OUT"
exec sudo -u tau env HOME=/home/tau QA_ADMIN_USER="$QA_ADMIN_USER" QA_ADMIN_PASS="$QA_ADMIN_PASS" \
  QA_USER="$QA_USER" QA_USER_PASS="$QA_USER_PASS" \
  node "$OPS/qa/shoot-ui.mjs" "$PW" "$OPS/evidence/ui/inventory.json" "$OUT" "https://api.victor-tau.xyz:8443" "$FILTER"
