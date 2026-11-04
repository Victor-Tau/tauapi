#!/usr/bin/env bash
# Backend rolling-release drill with live streams (QA by default).
#
#   1. start a bounded SSE stream (mock-slow-<sse>) and a WebSocket session
#      (<ws> seconds) through Nginx before the release begins
#   2. run deploy-backend.sh <image> (drain timeout <drain>)
#   3. record: per-chunk SSE arrival times, WS end reason, upstream connection
#      counts per backend port during the release, and container/image changes
#
# Usage: sudo release-drill.sh <image> [--sse 30] [--ws 20] [--drain 90] [--out DIR]
set -uo pipefail
source "$(dirname "$0")/../scripts/lib.sh"
require_root
IMAGE=${1:?image}; shift
SSE=30; WS=20; DRAIN=90; OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sse) SSE="$2"; shift 2 ;;
    --ws) WS="$2"; shift 2 ;;
    --drain) DRAIN="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    *) die "unknown argument $1" 2 ;;
  esac
done
[[ -n $OUT ]] || OUT=$OPS_ROOT/evidence/raw/drill-$TAUAPI_ENV-$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p "$OUT"
KEY=$(jq -r .key "$SECRET_ROOT/qa-token.json")
T0=$(date +%s.%N)
rel() { echo "$(date +%s.%N) - $T0" | bc | xargs printf '%.2f'; }

# 1) streams
( curl -sN "${CURL_RESOLVE[@]}" -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' \
    -d "{\"model\":\"mock-slow-$SSE\",\"stream\":true,\"messages\":[{\"role\":\"user\",\"content\":\"drill\"}]}" \
    "$TAUAPI_ORIGIN/v1/chat/completions" | while IFS= read -r line; do
      [[ $line == data:* ]] && printf '%s %s\n' "$(rel)" "$(grep -oE 'tick [0-9]+|\[DONE\]' <<<"$line" | head -1)"
    done; echo "$(rel) curl-exit=${PIPESTATUS[0]}" ) > "$OUT/sse.txt" 2>&1 &
SSE_PID=$!
( python3 -I "$OPS_ROOT/qa/ws-probe.py" --seconds "$WS" --port "$TAUAPI_HTTPS_PORT" --quiet ) > "$OUT/ws.txt" 2>&1 &
WS_PID=$!
sleep 3

# 2) connection sampler
( while kill -0 $SSE_PID 2>/dev/null || kill -0 $WS_PID 2>/dev/null || [[ -e $OUT/.deploying ]]; do
    printf '%s master=%s slave=%s\n' "$(rel)" "$(backend_conn_count "$MASTER_PORT")" "$(backend_conn_count "$SLAVE_PORT")"
    sleep 1
  done ) > "$OUT/conns.txt" &
SAMPLER=$!

{ echo "before:"; compose ps --format '{{.Service}} {{.ID}} {{.Image}} {{.Status}}' | grep backend; } > "$OUT/containers.txt"
touch "$OUT/.deploying"
"$OPS_ROOT/scripts/deploy-backend.sh" "$IMAGE" --drain-timeout "$DRAIN" > "$OUT/deploy.log" 2>&1
RC=$?
rm -f "$OUT/.deploying"
echo "$(rel) deploy-exit=$RC" >> "$OUT/deploy.log"
{ echo "after:"; compose ps --format '{{.Service}} {{.ID}} {{.Image}} {{.Status}}' | grep backend; } >> "$OUT/containers.txt"
wait $SSE_PID $WS_PID 2>/dev/null
sleep 1; kill $SAMPLER 2>/dev/null
echo "deploy_rc=$RC out=$OUT"
exit $RC
