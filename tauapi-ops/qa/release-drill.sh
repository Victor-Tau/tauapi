#!/usr/bin/env bash
# Backend rolling-release drill with live streams (QA by default).
#
#   1. start a bounded SSE stream (mock-slow-<sse>) and a WebSocket session
#      (<ws> seconds) through Nginx before the release begins
#   2. run deploy-backend.sh <image> (drain timeout <drain>)
#   3. record: per-chunk SSE arrival times, WS end reason, upstream connection
#      counts per backend port during the release, and container/image changes
#
# Usage: sudo release-drill.sh <image|rollback> [--sse 20] [--ws 20] [--drain 90] [--out DIR]
set -uo pipefail
source "$(dirname "$0")/../scripts/lib.sh"
# lib.sh enables errexit; the drill must survive a non-zero deploy (e.g. the
# intended exit 10 "drain incomplete") and always clean up its loops.
set +e
require_root
IMAGE=${1:?image}; shift
cleanup_drill() {
  rm -f "${OUT:-/nonexistent}/.deploying"
  for p in ${PROBE:-} ${SAMPLER:-}; do kill "$p" 2>/dev/null; done
}
trap cleanup_drill EXIT
SSE=20; WS=20; DRAIN=90; OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sse) SSE="$2"; shift 2 ;;
    --ws) WS="$2"; shift 2 ;;
    --drain) DRAIN="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    *) die "unknown argument $1" 2 ;;
  esac
done
case "$SSE" in 5|20|90|200) ;; *) die "--sse must be one of the QA mock models: 5 20 90 200" 2 ;; esac
[[ -n $OUT ]] || OUT=$OPS_ROOT/evidence/raw/drill-$TAUAPI_ENV-$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p "$OUT"
KEY=""
[[ -f $SECRET_ROOT/qa-token.json ]] && KEY=$(jq -r .key "$SECRET_ROOT/qa-token.json")
STREAMS=1
if [[ -z $KEY || $TAUAPI_ENV != qa ]]; then
  # Production has no mock channel and no test API key: only the
  # continuous new-request probe runs (SSE/WS drills are QA-only).
  STREAMS=0
fi
T0=$(date +%s.%N)
rel() { echo "$(date +%s.%N) - $T0" | bc | xargs printf '%.2f'; }

# 1) streams (QA only)
SSE_PID=""; WS_PID=""
if [[ $STREAMS == 1 ]]; then
( curl -sN "${CURL_RESOLVE[@]}" -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' \
    -d "{\"model\":\"mock-slow-$SSE\",\"stream\":true,\"messages\":[{\"role\":\"user\",\"content\":\"drill\"}]}" \
    "$TAUAPI_ORIGIN/v1/chat/completions" | while IFS= read -r line; do
      [[ $line == data:* ]] && printf '%s %s\n' "$(rel)" "$(grep -oE 'tick [0-9]+|\[DONE\]' <<<"$line" | head -1)"
    done; echo "$(rel) curl-exit=${PIPESTATUS[0]}" ) > "$OUT/sse.txt" 2>&1 &
SSE_PID=$!
( python3 -I "$OPS_ROOT/qa/ws-probe.py" --seconds "$WS" --port "$TAUAPI_HTTPS_PORT" --quiet ) > "$OUT/ws.txt" 2>&1 &
WS_PID=$!
fi
sleep 3

# 2) continuous new-request probe (every 0.2s) to show no failed requests
( ok=0; bad=0
  while [[ -e $OUT/.deploying || $ok -lt 5 ]]; do
    c=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "${CURL_RESOLVE[@]}" "$TAUAPI_ORIGIN/api/status")
    if [[ $c == 200 ]]; then ok=$((ok+1)); else bad=$((bad+1)); echo "$(rel) status=$c"; fi
    sleep 0.2
  done
  echo "requests_ok=$ok requests_failed=$bad" ) > "$OUT/probe.txt" 2>&1 &
PROBE=$!

# 3) connection sampler
( while { [[ -n $SSE_PID ]] && kill -0 $SSE_PID 2>/dev/null; } || { [[ -n $WS_PID ]] && kill -0 $WS_PID 2>/dev/null; } || [[ -e $OUT/.deploying ]]; do
    printf '%s master=%s slave=%s\n' "$(rel)" "$(backend_conn_count "$MASTER_PORT")" "$(backend_conn_count "$SLAVE_PORT")"
    sleep 1
  done ) > "$OUT/conns.txt" &
SAMPLER=$!

{ echo "before:"; compose ps --format '{{.Service}} {{.ID}} {{.Image}} {{.Status}}' | grep backend; } > "$OUT/containers.txt"
touch "$OUT/.deploying"
sleep 1
if [[ $IMAGE == rollback ]]; then
  # same drained procedure, target = previously recorded image
  "$OPS_ROOT/scripts/deploy-backend.sh" --rollback --skip-backup --drain-timeout "$DRAIN" > "$OUT/deploy.log" 2>&1
else
  "$OPS_ROOT/scripts/deploy-backend.sh" "$IMAGE" --drain-timeout "$DRAIN" > "$OUT/deploy.log" 2>&1
fi
RC=$?
rm -f "$OUT/.deploying"
echo "$(rel) deploy-exit=$RC" >> "$OUT/deploy.log"
{ echo "after:"; compose ps --format '{{.Service}} {{.ID}} {{.Image}} {{.Status}}' | grep backend; } >> "$OUT/containers.txt"
wait $SSE_PID $WS_PID $PROBE 2>/dev/null || true
sleep 1; kill $SAMPLER 2>/dev/null || true
chown -R "$(stat -c %U:%G "$OPS_ROOT")" "$OUT"
echo "deploy_rc=$RC out=$OUT"
exit $RC
