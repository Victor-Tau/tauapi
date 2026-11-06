# DEPLOYMENT (AI-facing runbook: deploy TauAPI on a new server)

Audience: an AI agent with root/sudo on a fresh host. Follow the phases in order and run every gate.
Status of this document: derived from the scripts in `tauapi-ops/scripts` that were verified on the original host.
The full sequence has NOT been executed end to end on a fresh host. Phase 5 (certificate) and the host
dependency install (phase 1) are not scripted; the commands given there are standard, not repo-verified.
Treat any failed gate as a stop: report evidence, do not improvise around it.

## 0. Hard rules

- Never run `docker compose down -v`, never delete named volumes `tauapi_*`, never regenerate files in `/etc/tauapi/`
  (the scripts already refuse to; do not bypass them).
- Never overwrite a production database with a restore. Restores are validated in an isolated DB only (`restore-check.sh`).
- Do not change SSH access or enable a firewall without explicit user approval.
- Do not push to QuantumNous upstream. Do not rename or remove New API / QuantumNous branding, licences, or attribution.
- Do not print secrets (`/etc/tauapi/*`, admin password) into logs or reports.
- All state-changing scripts take the deploy lock `/run/lock/tauapi-deploy.lock` themselves; do not run two at once.

## 1. Inputs and prerequisites

| Item | Requirement |
| --- | --- |
| OS | Ubuntu 24.04, x86_64, >= 4 vCPU, >= 4 GiB RAM (+ swap), >= 10 GiB free disk |
| DNS | `A` record of the target domain already points to this host; ports 80/443 reachable from the internet |
| Domain | default `api.victor-tau.xyz`; see phase 2 to change it |
| Egress | github.com, proxy.golang.org, registry.npmjs.org, registry-1.docker.io, acme-v02.api.letsencrypt.org |
| Packages | `docker` (engine + compose plugin), `nginx`, `certbot`, `git`, `jq`, `rsync`, `python3`, `curl`, `openssl` |
| Bun | exact version in `tauapi-fe/package.json` `packageManager` (`bun@X`), installed at `$HOME/.local/toolchains/bun-linux-x64/bun` (or set `BUN_BIN`). `build-frontend.sh` aborts on mismatch |
| Users | a non-root build user (builds run as that user, deploys via `sudo`) |
| Repo access | the repo is private on GitHub: `Victor-Tau/tauapi`; authenticate with `gh auth login` or another credential first |

Install the packages with apt (Docker from the distribution or Docker's apt repo; certbot from apt, which gives a
systemd `certbot.timer`). Do not install certbot through two different methods.

## 2. Fetch the code and set the domain

```bash
sudo git clone https://github.com/Victor-Tau/tauapi.git /opt/tauapi    # scripts hard-code /opt/tauapi
sudo chown -R "$USER": /opt/tauapi
cd /opt/tauapi/tauapi-ops
scripts/preflight.sh                                                   # gate: exit 0, review [FAIL]/[warn]
```

The domain is hard-coded. To deploy under another domain replace it everywhere, then commit:

```bash
grep -rln 'victor-tau' /opt/tauapi/tauapi-ops | xargs sed -i 's/api\.victor-tau\.xyz/NEW.DOMAIN/g'
grep -rn 'victor-tau' /opt/tauapi/tauapi-ops/scripts /opt/tauapi/tauapi-ops/templates   # expect no output
```

Files known to contain it: `scripts/lib.sh` (`TAUAPI_DOMAIN`), `preflight.sh`, `generate-nginx.py`,
`bootstrap-admin.py`, `smoke-auth.py`. Historic evidence/docs under `evidence/` may keep the old name.
Also check `scripts/bootstrap-stack.sh`: `TZ` in the rendered `backend.env` is `Asia/Singapore`; change if required.

Pinned inputs that must stay as they are: image digests in `bootstrap-stack.sh` (PostgreSQL 16.15, Redis 7.4.12),
`golang` digest in `tauapi-be/Dockerfile`, Bun version in `package.json`.

## 3. Build artefacts (as the build user)

```bash
cd /opt/tauapi/tauapi-ops
scripts/build-backend.sh --rev main        # prints BACKEND_COMMIT, IMAGE_TAG=tauapi-be:<commit12>, IMAGE_ID
scripts/build-frontend.sh --rev main --release-id fe-r1-$(git -C /opt/tauapi rev-parse --short HEAD)
```

Builds use `git archive main:<subdir>`, so they only see committed files. Commit changes (e.g. the domain edit)
before building. Frontend output: `/srv/tauapi/artifacts/frontend/<release-id>.tar.gz` (+ `.sha256`, manifest).
Gates: exit 0; backend image exists in `docker images`; frontend tests (typecheck + vitest) pass.
`build-backend.sh` needs docker access (use `sudo` if the build user is not in the `docker` group).

## 4. Start data layer and backend in maintenance mode

```bash
sudo scripts/bootstrap-stack.sh --backend-image tauapi-be:<commit12> --with-slave --nginx maintenance
```

Effects (idempotent): creates `/etc/tauapi/{postgres.env,redis.env,app-secrets.env,backend.env}` (0600, generated once),
renders `/srv/tauapi/stack/{compose.yml,images.env}`, starts postgres, redis, `backend-master` (127.0.0.1:3001,
runs migrations) and `backend-slave` (127.0.0.1:3002). Nginx serves only the ACME path and a 503 page; nothing
uninitialised is public.
Gates: exit 0 (exit 6 = unhealthy service: `sudo docker compose -p tauapi -f /srv/tauapi/stack/compose.yml logs --tail 100 <service>`);
`sudo docker ps` shows four healthy containers; `ss -tln` shows no 5432/6379 on host interfaces.

## 5. TLS certificate (not scripted)

The site config expects `/etc/letsencrypt/live/<domain>/{fullchain,privkey}.pem`. Issue it while the host is in
maintenance mode, using the webroot that Nginx serves for `/.well-known/acme-challenge/`:

```bash
sudo mkdir -p /var/www/tauapi-acme
sudo certbot certonly --webroot -w /var/www/tauapi-acme -d <domain> \
  --register-unsafely-without-email --agree-tos      # or: -m <email> when the user supplies one
printf '#!/bin/sh\nnginx -t && systemctl reload nginx\n' | sudo tee /etc/letsencrypt/renewal-hooks/deploy/tauapi-nginx.sh
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/tauapi-nginx.sh
sudo certbot renew --dry-run
systemctl is-active certbot.timer
```

If issuance fails because `/var/www/tauapi-acme` is not served, re-run `sudo scripts/set-site-mode.sh maintenance`
and check `curl -i http://<domain>/.well-known/acme-challenge/x` returns 404 from Nginx (not a redirect or 503).
Gates: certificate files exist; `renew --dry-run` succeeds; `certbot.timer` active.

## 6. Publish the frontend, initialise the admin, open the site

```bash
sudo scripts/deploy-frontend.sh fe-r1-<short>          # validates, publishes /_ui/<release>/, atomic switch, tags
sudo python3 -I scripts/bootstrap-admin.py             # loopback HTTPS; creates admin once; password -> /etc/tauapi/initial-admin.json (0600)
sudo scripts/set-site-mode.sh live                     # nginx -t gated; rolls back its own change on failure
sudo scripts/smoke.sh --public                         # gate: all checks pass (original host: 42/42)
```

`bootstrap-admin.py` also sets `SelfUseModeEnabled=true`, `DemoSiteEnabled=false`, `RegisterEnabled=false`,
`ServerAddress=https://<domain>`. Exit 3 = credentials missing (manual recovery), 4 = API failure.
Do not open `live` before the admin exists. Report the admin password location, never its value.

## 7. Boot units, backups, log rotation

```bash
sudo install -m 0644 /opt/tauapi/tauapi-ops/config/systemd/tauapi-stack.service  /etc/systemd/system/
sudo install -m 0644 /opt/tauapi/tauapi-ops/config/systemd/tauapi-backup.service /etc/systemd/system/
sudo install -m 0644 /opt/tauapi/tauapi-ops/config/systemd/tauapi-backup.timer   /etc/systemd/system/
sudo install -m 0644 /opt/tauapi/tauapi-ops/config/logrotate/tauapi-nginx /etc/logrotate.d/tauapi-nginx
sudo systemctl daemon-reload
sudo systemctl enable docker nginx tauapi-stack.service
sudo systemctl enable --now tauapi-backup.timer
sudo scripts/backup.sh --reason manual && sudo scripts/restore-check.sh   # gate: restore-check reports tables>0, root=1, app_read=ok
```

Backups are local only (`/var/backups/tauapi`). Tell the user there is no off-site copy unless one is configured.

## 8. Record state

```bash
sudo scripts/collect-evidence.sh        # refreshes tauapi-ops/DEPLOYMENT_STATE.json and evidence/SUMMARY-prod.md
```

Then update `tauapi-ops/STATUS.md` (English) and `tauapi-ops/HANDOFF.md` (Chinese) with real values, and commit.

## 9. Migrating an existing installation instead of a fresh one

A fresh run yields an empty site. To carry data over, before phase 6 `bootstrap-admin.py`:

1. Copy `/etc/tauapi/app-secrets.env` from the old host (same `SESSION_SECRET`/`CRYPTO_SECRET`, otherwise sessions and
   encrypted channel keys break) and place it before running `bootstrap-stack.sh`; the script keeps existing secret files.
2. Restore the old `pg_dump -Fc` into the new `tauapi` database while the backend is stopped. There is no restore
   script for production (by design); do this manually and only into an empty database.
3. Skip `bootstrap-admin.py` if the restored database already has the root user; verify with `smoke.sh --public`.

## 10. Troubleshooting map

| Symptom | Check |
| --- | --- |
| `bootstrap-stack.sh` exit 3 | missing `--backend-image` on first run, or empty secret file |
| backend not healthy | `docker compose ... logs backend-master`; DB/Redis health; `backend.env` rendered |
| site 503 after `live` | admin not initialised or maintenance gate active; run `set-site-mode.sh live` after phase 6 |
| `bootstrap-admin.py` fails TLS | certificate missing (phase 5) or domain not replaced everywhere |
| frontend deploy exit 8 | verification failed and the previous release was restored automatically; read its output |
| lock error (exit 9) | another deploy holds `/run/lock/tauapi-deploy.lock`; wait, do not delete the lock |

Day-2 operations (frontend/backend release and rollback, upstream sync, backups): see `tauapi-ops/HANDOFF.md` §7–9
and `map.md` §8.
