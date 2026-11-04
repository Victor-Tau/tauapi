# HANDOFF — TauAPI (tauapi-fe / tauapi-be) on api.victor-tau.xyz

Date: 2026-11-04 (UTC). Host: Ubuntu 24.04.5, 4 vCPU, 3.8 GiB RAM + 4 GiB swap, single server.
Upstream: QuantumNous/new-api `ba5f7367797566175a6cd97a748d430af3602a01` (verified from GitHub). New API / QuantumNous branding, copyright and module paths are unchanged (protected by upstream rules).

## 1. URL and current state

- **https://api.victor-tau.xyz** is live (public mode). Frontend and API share this origin.
- Public smoke `scripts/smoke.sh --public`: **42/42 passed** (pages, API, plugins, assets, cache headers, hidden files, HTTP→HTTPS, TLS, login/refresh/logout).
- Running: frontend `fe-r3-0dab41b`; backend master + slave `tauapi-be:a4231663776e`; PostgreSQL 16.15; Redis 7.4.12; Nginx 1.24.0.

## 2. Repository (single TauAPI monorepo)

| Item | Value |
| --- | --- |
| Repository | `/opt/tauapi` (one Git repo; subdirectories `tauapi-fe/`, `tauapi-be/`, `tauapi-ops/`, plus `README.md`, `map.md`) |
| Remote | `origin` → `/var/lib/tauapi/git/tauapi.git` (bare, branch `main`) |
| Branches | `main` (all customisations); `vendor/upstream-fe`, `vendor/upstream-be` (raw upstream imports in split layout) |
| Tags | `upstream/fe-ba5f73677975`, `upstream/be-ba5f73677975`, `release/fe-r1-aade206`, `release/fe-r2-3097ff7`, `release/fe-r3-0dab41b`, `release/be-53c0e999057f`, `release/be-a4231663776e` |
| History | the three former repos were merged as subtrees with full history (`git log -- tauapi-fe/` etc. still works; `git log --follow` across the move is not needed because each part keeps its own path prefix from the merge commit on) |
| Archive of the split era | `/var/lib/tauapi/git/archive-split-20261104/tauapi-{fe,be,ops}.bundle` (verified); the old bare remotes `tauapi-{fe,be,ops}.git` are kept unused |

- Frontend and backend remain **separate build/release units**: `build-frontend.sh` / `build-backend.sh` export only `main:tauapi-fe` / `main:tauapi-be` with `git archive`, so neither build sees the other directory. Release IDs carry the monorepo commit.
- Distribute with `git clone /var/lib/tauapi/git/tauapi.git` or `git -C /opt/tauapi bundle create tauapi.bundle --all`.
- Read-only upstream cache: `/var/cache/tauapi/upstream`. Commit identity: `TauAPI Maintainer <tauapi-maintainer@localhost>` (repo-local).
- No external remote is configured; nothing was pushed to GitHub or upstream. To add one: `git -C /opt/tauapi remote add github <url> && git push github main vendor/upstream-fe vendor/upstream-be --tags`.
- Each backup writes `/var/backups/tauapi/git/tauapi-<time>.bundle`.

## 3. Release artefacts

| Unit | Release | Identity |
| --- | --- | --- |
| Frontend (current) | fe-r3-0dab41b | commit 0dab41b8b090…, tar.gz sha256 `269fb7fcc3573b814e94b05057c16b1d17767dabba20bf9790db8770067b1d7c`, assets `/_ui/fe-r3-0dab41b/` |
| Frontend (rollback target) | fe-r2-3097ff7 | sha256 `fa75539cb1082b4417560e11c0c11099a93b2299a0d7b512db385e9830990058` |
| Frontend (pre-Flat) | fe-r1-aade206 | sha256 `33529454fd418d45ec9967fe10cd6f0fbce583e4b3d78f75d00603477d0ee9a3` |
| Backend (current) | tauapi-be:a4231663776e | image `sha256:d5d09addfebb6395923d3443ea3a26430fc2e33891dfd177007bf8b650df8639`, version `0.0.0+be.a4231663776e` |
| Backend (rollback target) | tauapi-be:53c0e999057f | image `sha256:74cfee86d4c0d363c9d75108344c61b0f375e73c53acad2aa0a7eb9a51aff531` |
| PostgreSQL | postgres:16-bookworm@sha256:e8a07d2c…bd938 | 16.15 |
| Redis | redis:7.4-bookworm@sha256:b6b6e3dc…882f5 | 7.4.12 |

Backend images are local builds (no registry), so there is no registry digest; they are identified by image ID plus the `org.opencontainers.image.revision` label. Builder and runtime base images are pinned by digest in the Dockerfile. Upstream `VERSION` is empty at this SHA, so app versions show as `0.0.0+be.<commit>` / `0.0.0+fe.<commit>`.

## 4. Minimalist Flat

The design was applied to all first-party UI. See `evidence/UI_REVIEW.md` (scope, what changed, screenshots inspected) and `UI_INVENTORY.csv` (77 routes/sections, each with a light/dark/mobile verdict and evidence path).

- Tests: 2465/2465 pass. Contrast: 16/16 pass. Overlays: 17/17. Matrix: 230/231 captures.
- The one capture that missed: the invalid OAuth callback on mobile redirects to sign-in before the capture, which is expected behaviour.
- Implementation rules for future work: `docs/MINIMALIST_FLAT.md`.

## 5. Administrator

- Username: **admin**.
- The password is stored only in the root-only file **`/etc/tauapi/initial-admin.json`** (mode 0600). It is not printed anywhere.
- To read it on the server: `sudo jq -r .password /etc/tauapi/initial-admin.json`. Then sign in at https://api.victor-tau.xyz/sign-in and change the password (Security & Access).
- Public registration is **off**, self-use mode is on, demo mode is off.

## 6. Topology, ports, data, secrets

```
Internet ─▶ Nginx :80 (ACME + 301) / :443 (TLS, /etc/nginx/sites-available/tauapi.conf)
   ├─ registered SPA pages ─▶ /srv/tauapi/current/frontend/index.html   (no-store)
   ├─ /_ui/<release>/…     ─▶ /srv/tauapi/public/_ui/<release>/          (immutable; 404 if missing)
   ├─ /_meta/ui-version.json
   └─ everything else      ─▶ upstream tauapi_backend
                               ├─ backend-master 127.0.0.1:3001 (NODE_TYPE=master, migrations)
                               └─ backend-slave  127.0.0.1:3002 (NODE_TYPE=slave)
                                   └─ internal network: postgres:5432, redis:6379 (no host ports)
```

- Compose project `tauapi`: `/srv/tauapi/stack/compose.yml` and `images.env`, both rendered from `tauapi-ops/templates/compose.yml`.
- Volumes: `tauapi_pgdata`, `tauapi_redisdata`, `tauapi_master_data`, `tauapi_slave_data`.
- Secrets, all root-only 0600 in `/etc/tauapi/`: `postgres.env`, `redis.env`, `app-secrets.env` (SESSION_SECRET, CRYPTO_SECRET), `backend.env` (derived from the others), `initial-admin.json`. They are generated once and never regenerated.
- Nginx includes:
  - `/etc/nginx/tauapi/upstream-backend.conf` (the active set), `proxy-backend.conf`, `security-headers.conf`
  - `/etc/nginx/conf.d/tauapi-common.conf`
  - `/etc/nginx/modules-enabled/90-tauapi-main.conf` (`worker_shutdown_timeout 660s`)
- Firewall: UFW stays inactive and SSH is unchanged. The cloud security group was not inspected (no account access). Only 22, 80 and 443 listen publicly.

## 7. Release commands (all scripts in /opt/tauapi/tauapi-ops/scripts; take the deploy lock themselves)

```bash
# Frontend
scripts/build-frontend.sh --rev main --release-id fe-r4-<short>     # as tau; typecheck+test unless --skip-checks
sudo scripts/deploy-frontend.sh fe-r4-<short>                        # validate, publish /_ui, atomic switch, verify, auto-restore on failure, tag
sudo scripts/rollback-frontend.sh [<release-id>]                     # no rebuild; default = previous release
sudo scripts/prune-frontend.sh [--apply]                             # keeps newest 5 + <30 days + current + rollback target

# Backend
scripts/build-backend.sh --rev main                                  # git-archive context, prints IMAGE_TAG
sudo scripts/deploy-backend.sh tauapi-be:<commit12>                  # backup, master then slave, drained, verified, tagged
sudo scripts/rollback-backend.sh                                     # same procedure back to the recorded previous image

# Checks / ops
sudo scripts/smoke.sh --public
sudo scripts/backup.sh --reason manual ; sudo scripts/restore-check.sh
sudo scripts/collect-evidence.sh                                    # refresh DEPLOYMENT_STATE.json + evidence/SUMMARY-prod.md
scripts/preflight.sh ; scripts/verify-independent-builds.sh all
sudo scripts/set-site-mode.sh maintenance|live                       # maintenance = ACME + loopback only
```

Exit code 10 from `deploy-backend.sh` means the instance still holds long-lived connections after the drain window. The script did **not** stop it. Re-run it later, or restore traffic with `sudo scripts/set-upstream.sh both`.

## 8. Upstream sync

- Run `scripts/sync-upstream.sh <sha|tag>`. It imports onto `vendor/upstream-fe` / `vendor/upstream-be` (a re-run is a no-op), creates `upgrade/<short-sha>` from main and subtree-merges them into `tauapi-fe/` and `tauapi-be/`. It never rewrites main and never deploys anything.
- Gates before merging to main:
  - backend: `go build .`, `go test ./...`, plus relaykit and tokenkit;
  - frontend: install, typecheck, test, build;
  - fixture sha256 comparison (`UPSTREAM.json`);
  - schema, auth and plugin review;
  - `ROUTE_CONTRACT.json` refresh if `src/routes` changed.
- No timer pulls upstream automatically.

## 9. TLS, logs, backups, restore

- **TLS:** certbot 2.9 (apt) with webroot `/var/www/tauapi-acme`, account registered without email (none was provided). `certbot.timer` is active and `renew --dry-run` passes. The deploy hook runs `nginx -t && systemctl reload nginx`. Expires 2027-02-02.
- **Logs:**
  - Nginx: `/var/log/nginx/tauapi.{access,error}.log` record the path only (no query strings, cookies or auth headers); rotated daily, 14 kept.
  - Docker json-file logs: 20 MB × 5 per container.
- **Backups:**
  - `tauapi-backup.timer` runs daily at 03:30 UTC: `pg_dump -Fc` plus git bundles plus manifests, kept 7 daily + 4 weekly.
  - `deploy-backend.sh` also takes a backup before every release.
  - **Local only** (`/var/backups/tauapi`): there is no off-site copy, so losing this host would lose code history and data together.
- **Restore drill** (`restore-check.sh`, latest dump into an isolated tmpfs PostgreSQL): 38 tables, root user and setup row present, and the backend image read the restored database. The production database is never overwritten automatically.

## 10. Evidence and external integrations

- Evidence files:
  - `evidence/ACCEPTANCE.md`: GOAL §19 item by item;
  - `evidence/RELEASE_DRILLS.md`, `evidence/UI_REVIEW.md`, `evidence/ui/CONTRAST.md`;
  - `evidence/SUMMARY-prod.md`, `evidence/P0-preflight.md`, `DEPLOYMENT_STATE.json`.
- Raw logs and screenshots are kept locally (git-ignored) under `evidence/raw/`.
- **Not configured / not verified with real providers:**
  - Model providers: no API keys and no production channels. Relay, SSE and WS were verified only against an internal **mock** upstream in the isolated QA stack; no real model call has been made.
  - SMTP: not configured, so password-reset and verification emails are unverified (the pages render).
  - OAuth / OIDC / WeChat / Telegram / Passkey RP: not configured (the callback page renders and handles failures).
  - Payment (Stripe, epay, Creem, Waffo): not configured. No orders were created.
  - Analytics (Umami / GA): not enabled.
  - Uptime Kuma, Worker proxy: not configured.

## 11. Blockers, safe state, next steps

- No blocking issues. The site is live and every core gate passed.
- **NTP:** timesyncd is active but has received no packets from ntp.ubuntu.com (outbound UDP 123 appears filtered by the provider). The clock currently matches public HTTPS `Date` headers within 1 s. If you control the cloud firewall, allow outbound UDP 123, or point timesyncd at a reachable NTP server.
- **Off-site backup:** provide a target (another host, or object storage with credentials) to get disaster recovery.
- **Optional cleanup** (left untouched on purpose):
  - Docker volumes `newapi_*` from the first bootstrap run before the TauAPI rename. They hold only an initial admin, no user data. Remove with `sudo docker volume rm newapi_pgdata newapi_redisdata newapi_master_data newapi_slave_data`.
  - QA volumes `tauapi-qa_*` and `/etc/tauapi-qa`: QA is stopped and its Nginx site disabled. Restart it with `sudo TAUAPI_ENV=qa scripts/bootstrap-stack.sh --with-slave --nginx live` (also re-enables the loopback site).
- **Sudo password:** the password you shared was cached at `~tau/.config/tauapi-sudo/` (0600) during the work and **deleted at handoff**. It appeared in chat, so consider changing it.

## 12. Capability limits

- Single server, so there is no high availability against host failure. The master/slave pair only removes per-instance downtime during releases.
- **New requests** switch instances without errors (0 failed of ~280 probe requests across 5 rolling runs).
- **Bounded SSE** streams that end within the drain window complete normally.
- **Long-lived WebSockets** are not migrated:
  - an instance that still holds one is not stopped (exit 10) and the operator decides;
  - clients reconnect afterwards;
  - no session resumption is promised.
- Backend instances are capped at 900 MB of memory each; SQL connection pools are capped at 25 open / 5 idle per instance.
