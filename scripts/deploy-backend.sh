#!/usr/bin/env bash
# Rolling backend release: master then slave, one instance at a time, each
# taken out of the Nginx upstream and drained before it is replaced.
#
# Usage: sudo deploy-backend.sh <image-ref> [--skip-backup] [--drain-timeout 180]
#        sudo deploy-backend.sh --rollback   (uses the image recorded as previous)
# Exit codes: 0 ok, 2 usage, 3 precondition, 6 new instance unhealthy (traffic
#             kept on the other instance), 10 drain did not finish (instance kept
#             serving its existing connections; nothing killed), 9 lock.
source "$(dirname "$0")/lib.sh"
source "$(dirname "$0")/lib-frontend.sh"
require_root

IMAGE=""
SKIP_BACKUP=0
DRAIN_TIMEOUT=180
ROLLBACK=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-backup) SKIP_BACKUP=1; shift ;;
    --drain-timeout) DRAIN_TIMEOUT="$2"; shift 2 ;;
    --rollback) ROLLBACK=1; shift ;;
    -*) die "unknown argument $1" 2 ;;
    *) IMAGE="$1"; shift ;;
  esac
done
acquire_lock
# shellcheck disable=SC1090
source "$IMAGES_ENV"
CUR_MASTER=$BACKEND_MASTER_IMAGE
CUR_SLAVE=$BACKEND_SLAVE_IMAGE
STATE_FILE=$STATE_DIR/backend-release.json

if [[ $ROLLBACK == 1 ]]; then
  [[ -f $STATE_FILE ]] || die "no recorded backend release to roll back from" 3
  IMAGE=$(jq -r '.previous_image // empty' "$STATE_FILE")
  [[ -n $IMAGE ]] || die "no previous image recorded" 3
  log "rollback target: $IMAGE (compatibility: initial split adds no schema changes; see DEPLOYMENT_STATE.json)"
fi
[[ -n $IMAGE ]] || die "usage: deploy-backend.sh <image-ref> | --rollback" 2
docker image inspect "$IMAGE" >/dev/null 2>&1 || die "image $IMAGE not present locally" 3
NEW_ID=$(docker image inspect -f '{{.Id}}' "$IMAGE")
NEW_REV=$(docker image inspect -f '{{index .Config.Labels "org.opencontainers.image.revision"}}' "$IMAGE")

# ---- preconditions ---------------------------------------------------------
for addr in $MASTER_ADDR $SLAVE_ADDR; do
  wait_status_ok "http://$addr/api/status" 10 || die "instance $addr not healthy before release" 3
done
FE_BEFORE=$(readlink "$FRONTEND_CURRENT" || true)
if [[ $SKIP_BACKUP == 0 ]]; then
  "$OPS_ROOT/scripts/backup.sh" --reason "pre-backend-release" || die "pre-release backup failed" 3
fi
log "release $IMAGE ($NEW_ID rev ${NEW_REV:0:12}); current master=$CUR_MASTER slave=$CUR_SLAVE"

write_images() { # master slave
  sed -e "s|^BACKEND_MASTER_IMAGE=.*|BACKEND_MASTER_IMAGE=$1|" \
      -e "s|^BACKEND_SLAVE_IMAGE=.*|BACKEND_SLAVE_IMAGE=$2|" "$IMAGES_ENV" > "$IMAGES_ENV.tmp"
  mv -f "$IMAGES_ENV.tmp" "$IMAGES_ENV"
}

# Wait until Nginx has no established upstream connection to the port. Old
# Nginx workers finish their in-flight requests after reload; long SSE/WS
# streams keep the count > 0 until they end.
drain() { # port name
  local port=$1 name=$2 start n
  start=$(date +%s)
  sleep 2
  while :; do
    n=$(backend_conn_count "$port")
    (( n == 0 )) && { log "$name drained after $(( $(date +%s) - start ))s"; return 0; }
    if (( $(date +%s) - start >= DRAIN_TIMEOUT )); then
      log "$name still has $n upstream connection(s) after ${DRAIN_TIMEOUT}s"
      return 1
    fi
    sleep 1
  done
}

verify_instance() { # addr expected_image_id
  local addr=$1 want=$2 svc cid
  wait_status_ok "http://$addr/api/status" 180 || return 1
  [[ $addr == "$MASTER_ADDR" ]] && svc=backend-master || svc=backend-slave
  cid=$(container_id "$svc")
  [[ $(docker inspect -f '{{.Image}}' "$cid") == "$want" ]] || { log "$svc runs unexpected image"; return 1; }
  # real DB access through the app (setup state is read from the database)
  curl -fsS --max-time 10 "http://$addr/api/setup" | jq -e '.data.status == true' >/dev/null || return 1
  curl -fsS --max-time 10 "http://$addr/api/status" | jq -e '.data.server_address == "'"$TAUAPI_ORIGIN"'"' >/dev/null || return 1
  # unknown API path must stay a JSON 404
  [[ $(curl -s -o /dev/null -w '%{http_code}' "http://$addr/api/__no_such_route__") == 404 ]] || return 1
  return 0
}

replace_instance() { # svc addr port other_upstream new_master_image new_slave_image
  local svc=$1 addr=$2 port=$3 other=$4
  log "== $svc: remove from upstream (traffic -> $other)"
  "$OPS_ROOT/scripts/set-upstream.sh" "$other"
  if ! drain "$port" "$svc"; then
    log "drain incomplete: $svc keeps serving its existing connections; NOT stopping it"
    echo "{\"phase\":\"drain-$svc\",\"image\":\"$IMAGE\",\"at\":\"$(date -u +%FT%TZ)\"}" > "$STATE_DIR/backend-release-paused.json"
    exit 10
  fi
  write_images "$5" "$6"
  compose up -d --no-deps "$svc"
  if ! verify_instance "$addr" "$NEW_ID"; then
    log "$svc failed verification on new image; traffic stays on $other"
    exit 6
  fi
  log "$svc verified on new image"
  "$OPS_ROOT/scripts/set-upstream.sh" both
}

# master first (it owns migrations and background jobs), then slave.
replace_instance backend-master "$MASTER_ADDR" "$MASTER_PORT" slave "$IMAGE" "$CUR_SLAVE"
replace_instance backend-slave "$SLAVE_ADDR" "$SLAVE_PORT" master "$IMAGE" "$IMAGE"

# ---- final checks -------------------------------------------------------------
masters=$(compose ps --format '{{.Service}}' | grep -cx backend-master)
slaves=$(compose ps --format '{{.Service}}' | grep -cx backend-slave)
[[ $masters == 1 && $slaves == 1 ]] || die "expected exactly one master and one slave (got $masters/$slaves)" 6
FE_AFTER=$(readlink "$FRONTEND_CURRENT" || true)
[[ $FE_BEFORE == "$FE_AFTER" ]] || log "WARNING: frontend current changed during backend release"
PREV=$CUR_MASTER
[[ $ROLLBACK == 1 ]] && PREV=$(jq -r '.image' "$STATE_FILE")
cat > "$STATE_FILE" <<EOF
{
  "image": "$IMAGE",
  "image_id": "$NEW_ID",
  "backend_commit": "$NEW_REV",
  "previous_image": "$PREV",
  "action": "$([[ $ROLLBACK == 1 ]] && echo rollback || echo deploy)",
  "frontend_current_unchanged": $([[ $FE_BEFORE == "$FE_AFTER" ]] && echo true || echo false),
  "at": "$(date -u +%FT%TZ)"
}
EOF
rm -f "$STATE_DIR/backend-release-paused.json"
printf '%s %s %s prev=%s\n' "$(date -u +%FT%TZ)" "$(jq -r .action "$STATE_FILE")" "$IMAGE" "$PREV" >> "$STATE_DIR/backend-releases.log"
log "backend release complete: master+slave on $IMAGE; frontend unchanged: $([[ $FE_BEFORE == "$FE_AFTER" ]] && echo yes || echo NO)"
