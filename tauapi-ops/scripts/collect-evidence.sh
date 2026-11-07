#!/usr/bin/env bash
# Collect a redacted, committable evidence summary (no secrets, no env dumps,
# no cookies/tokens). Raw outputs stay under evidence/raw (git-ignored).
# Usage: sudo collect-evidence.sh  -> writes evidence/SUMMARY-<environment>.md and DEPLOYMENT_STATE.json
source "$(dirname "$0")/lib.sh"
require_root
EV=$OPS_ROOT/evidence
mkdir -p "$EV/raw"
# shellcheck disable=SC1090
source "$IMAGES_ENV"
img_id() { docker image inspect -f '{{.Id}}' "$1" 2>/dev/null; }
img_digest() { docker image inspect -f '{{if .RepoDigests}}{{index .RepoDigests 0}}{{end}}' "$1" 2>/dev/null; }
svc_line() { # service
  local cid; cid=$(container_id "$1")
  [[ -n $cid ]] || { echo "absent"; return; }
  docker inspect -f '{{.Config.Image}} id={{.Image}} started={{.State.StartedAt}} health={{if .State.Health}}{{.State.Health.Status}}{{end}} node_type={{range .Config.Env}}{{if eq (index (split . "=") 0) "NODE_TYPE"}}{{.}}{{end}}{{end}}' "$cid"
}
FE_REL=$(basename "$(readlink "$FRONTEND_CURRENT")")
FE_MAN=$FRONTEND_RELEASES/$FE_REL/release-manifest.json
PG_VER=$(docker exec "$(container_id postgres)" psql -U tauapi -d tauapi -Atc 'show server_version' 2>/dev/null)
RD_VER=$(docker exec "$(container_id redis)" redis-server --version 2>/dev/null | grep -oE 'v=[0-9.]+' | cut -d= -f2)
NGX_VER=$(nginx -v 2>&1 | cut -d/ -f2)
CERT_END=$(openssl x509 -enddate -noout -in /etc/letsencrypt/live/$TAUAPI_DOMAIN/cert.pem | cut -d= -f2)

cat > "$OPS_ROOT/DEPLOYMENT_STATE.json" <<EOF
{
  "environment": "$TAUAPI_ENV",
  "public_origin": "$TAUAPI_ORIGIN",
  "site_mode": "$(cat "$STATE_DIR/site-mode" 2>/dev/null)",
  "active_upstream": "$(cat "$STATE_DIR/active-upstream" 2>/dev/null)",
  "frontend": {
    "current_release": "$FE_REL",
    "frontend_commit": "$(jq -r .frontend_commit "$FE_MAN")",
    "upstream_commit": "$(jq -r .upstream_commit "$FE_MAN")",
    "asset_prefix": "$(jq -r .asset_prefix "$FE_MAN")",
    "artifact_sha256": "$(cut -d' ' -f1 "$ARTIFACT_ROOT/frontend/$FE_REL.tar.gz.sha256" 2>/dev/null)",
    "published_releases": $(ls -1 "$FRONTEND_RELEASES" | grep -v '^\.' | jq -R . | jq -s .)
  },
  "backend": {
    "master": {"bind": "$MASTER_ADDR", "image": "$BACKEND_MASTER_IMAGE", "image_id": "$(img_id "$BACKEND_MASTER_IMAGE")",
               "commit": "$(docker image inspect -f '{{index .Config.Labels "org.opencontainers.image.revision"}}' "$BACKEND_MASTER_IMAGE")"},
    "slave":  {"bind": "$SLAVE_ADDR", "image": "$BACKEND_SLAVE_IMAGE", "image_id": "$(img_id "$BACKEND_SLAVE_IMAGE")",
               "commit": "$(docker image inspect -f '{{index .Config.Labels "org.opencontainers.image.revision"}}' "$BACKEND_SLAVE_IMAGE")"},
    "last_release": $(cat "$STATE_DIR/backend-release.json" 2>/dev/null || echo null)
  },
  "data": {
    "postgres_image": "$POSTGRES_IMAGE", "postgres_version": "$PG_VER",
    "redis_image": "$REDIS_IMAGE", "redis_version": "$RD_VER",
    "volumes": $(docker volume ls --format '{{.Name}}' | grep "^${COMPOSE_PROJECT}_" | jq -R . | jq -s .),
    "schema_compatibility": "Initial split and UI work add no schema changes; master runs upstream AutoMigrate on start. Backend rollback between be-r1/be-r2 is symmetric (same schema)."
  },
  "nginx_version": "$NGX_VER",
  "certificate_not_after": "$CERT_END",
  "generated_at": "$(date -u +%FT%TZ)"
}
EOF
jq . "$OPS_ROOT/DEPLOYMENT_STATE.json" >/dev/null || die "DEPLOYMENT_STATE.json invalid" 4

{
  echo "# Deployment evidence ($TAUAPI_ENV) — $(date -u +%FT%TZ)"
  echo
  echo "## Running services"
  echo '```'
  for s in backend-master backend-slave postgres redis; do printf '%-15s %s\n' "$s" "$(svc_line $s)"; done
  echo '```'
  echo "## Listening ports"
  echo '```'
  ss -Htln | awk '{print $4}' | sort -u
  echo '```'
  echo "## Versions"
  echo "- frontend release: $FE_REL ($(jq -r .frontend_commit "$FE_MAN" | cut -c1-12))"
  echo "- backend: $BACKEND_MASTER_IMAGE / $BACKEND_SLAVE_IMAGE"
  echo "- PostgreSQL $PG_VER, Redis $RD_VER, Nginx $NGX_VER"
  echo "- certificate notAfter: $CERT_END"
  echo "## Release log"
  echo '```'
  cat "$STATE_DIR/frontend-releases.log" "$STATE_DIR/backend-releases.log" 2>/dev/null || true
  echo '```'
  echo "## Backup and restore checks"
  echo '```'
  ls -1t "$BACKUP_ROOT/db" 2>/dev/null | grep -E '\.dump$' | head -5 || true
  cat "$STATE_DIR/restore-checks.log" 2>/dev/null || true
  echo '```'
  echo "## Timers"
  echo '```'
  systemctl list-timers --no-pager certbot.timer tauapi-backup.timer | head -4 || true
  echo '```'
} > "$EV/SUMMARY-$TAUAPI_ENV.md"
# Redaction guard: refuse to leave anything that looks like a secret.
if grep -RIEn '(sk-[A-Za-z0-9]{20,}|password=|PASSWORD=|SESSION_SECRET=|CRYPTO_SECRET=|Bearer [A-Za-z0-9._-]{20,}|postgresql://[^ ]*:[^ ]*@)' \
     "$EV"/*.md "$OPS_ROOT/DEPLOYMENT_STATE.json" 2>/dev/null; then
  die "possible secret in evidence; refusing" 4
fi
owner=$(stat -c %U:%G "$OPS_ROOT")
chown "$owner" "$EV/SUMMARY-$TAUAPI_ENV.md" "$OPS_ROOT/DEPLOYMENT_STATE.json"
chmod 0644 "$EV/SUMMARY-$TAUAPI_ENV.md" "$OPS_ROOT/DEPLOYMENT_STATE.json"
echo "wrote $EV/SUMMARY-$TAUAPI_ENV.md and DEPLOYMENT_STATE.json"
