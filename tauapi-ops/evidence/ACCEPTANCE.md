# GOAL §19 acceptance checklist — real status (2026-11-04)

Legend: ✅ verified (evidence linked) · ⚠️ done with stated limitation · ⛔ not done

## A. Repositories and builds
| Item | Status | Evidence |
| --- | --- | --- |
| frontend/backend in different dirs, different git-common-dir | ⚠️ superseded | verified as separate repos during delivery; on 2026-11-04 merged into one monorepo `/opt/tauapi` at the user's request (DECISIONS 19). Build/release independence kept via `git archive main:<subdir>` |
| parent dir not a repo | ⚠️ superseded | `/opt/tauapi` is now the monorepo (user request) |
| source commits, custom commits, release tags, verified bundles | ✅ | `vendor/upstream` + `main`, tags `upstream/ba5f73677975`, `release/fe-r1/r2/r3`, `release/be-53c0e999057f`, `release/be-a4231663776e`; bundles `/var/backups/tauapi/git/*.bundle` verified |
| clean trees, no secrets/DB/cache in git | ✅ | `git status` clean in all three; secret-pattern scan only matches generator code; `evidence/raw` git-ignored |
| frontend builds without Go/sibling repo | ✅ | `scripts/verify-independent-builds.sh fe`: clone alone, PATH without Go → install/typecheck/test (2465 pass)/build OK, 0 cross-repo refs, 0 backend files in dist |
| backend builds without web/, Bun/Node, placeholder HTML | ✅ | clean clone inside `golang:1.26.10-alpine@sha256:9ce2…` (node/bun/npm absent): `go build .` OK, root 47 pkgs ok / 0 FAIL, relaykit 9 ok, tokenkit ok; no `index.html` |
| shared fixture traceable, plugins kept | ✅ | `testdata/contracts/frontend_simulation.json` sha256 `1569342e…35e3` = backend `pkg/billingexpr/testdata` = `UPSTREAM.json`; `plugins/tasks/*.js` kept |
| upstream sync does not overwrite main | ✅ | `sync-upstream.sh` rerun for the pinned SHA: import no-op, `upgrade/<sha>` merge, main and vendor/upstream unchanged |

## B. UI
| Item | Status | Evidence |
| --- | --- | --- |
| all first-party routes and dynamic sections in matrix | ✅ | `UI_INVENTORY.csv` 77 rows (route tree + 11 section registries + auth/error/setup) |
| shared controls/layout/dialogs/tables/charts/code unified | ✅ | `evidence/UI_REVIEW.md` |
| flat across home, user console, all admin settings | ✅ | 230/231 matrix captures pass; overlays 17/17 |
| dark/light, preferences, i18n, number formatting | ✅ | tokens both themes; presets/font/density/radius kept; 7 locales; tests 2465 pass; formatting code untouched |
| mobile interactions and main page layouts | ✅ | 390×844 captures, mobile sidebar sheet, mobile menus, card-list fallbacks |
| keyboard, focus, contrast | ✅ | `evidence/ui/CONTRAST.md` 16/16; keyboard check (tab order, focus ring, Enter, Escape + focus return, Ctrl+K) |
| no removed features / fake UI / global-CSS-only | ✅ | 173-file source change, same test count, no global `!important` overrides |
| screenshots actually reviewed | ✅ | list in `evidence/UI_REVIEW.md` |

## C. Deployment and auth
| Item | Status | Evidence |
| --- | --- | --- |
| valid public certificate | ✅ | Let's Encrypt (YE2), CN api.victor-tau.xyz, notAfter 2027-02-02; smoke `ssl_verify_result=0` from public IP |
| HTTP redirect, ACME exception, renew dry-run | ✅ | 301 keeps path+query; ACME path served from `/var/www/tauapi-acme`; `certbot renew --dry-run` succeeded; `certbot.timer` active; deploy hook `nginx -t && reload` |
| uninitialised service never public | ✅ | maintenance gate (real source IP) until admin init; public returned 503 even with spoofed `X-Forwarded-For` |
| admin created, public address, credentials safe | ✅ | `admin`, `/etc/tauapi/initial-admin.json` (root 0600); `ServerAddress=https://api.victor-tau.xyz` |
| self-use, non-demo, registration off | ✅ | `/api/status`: self_use_mode_enabled=true, demo_site_enabled=false, register_enabled=false |
| Secure cookie / trusted URL / proxies | ✅ | `SESSION_COOKIE_SECURE=true`, `SESSION_COOKIE_TRUSTED_URL=https://api.victor-tau.xyz`, `TRUSTED_PROXIES=172.30.70.1/32`; session IP recorded as real client, not bridge |
| login/refresh/logout and after-restart sessions | ✅ | public `smoke-auth.py`: wrong password rejected, Secure+HttpOnly refresh cookie, refresh needs Origin, rotation, logout, post-logout refresh 401; QA: session refresh works after restarting both backends |
| DB/Redis/backend ports not public | ✅ | listeners: 22, 80, 443 public; 3001/3002 on 127.0.0.1; no 5432/6379 host ports |
| exactly one master + one slave, same secrets/DB | ✅ | `DEPLOYMENT_STATE.json`, `SUMMARY-prod.md` |

## D. Routing and releases
| Item | Status | Evidence |
| --- | --- | --- |
| SPA deep links and /oauth pages | ✅ | smoke 16 page checks incl. `/oauth/github`, `/user/reset`, legacy `/login`, `/console/token` |
| /api, /v1, /v1beta, /pg, MJ, plugin paths to backend | ✅ | smoke: JSON responses for all; plugin `/ali/...`, `/tasks`, `/suno/fetch` reach dispatcher |
| /dashboard/billing before dashboard page | ✅ | `/dashboard/billing/usage` → 401 JSON |
| unknown API not HTML 200; missing asset 404 | ✅ | `/api/__nope__` 404 JSON; missing `/_ui/...js` 404, not cached |
| SSE immediate, WS upgrade + drain boundary | ✅ | `evidence/RELEASE_DRILLS.md` (1 chunk/s through Nginx; 101; >window WS → release paused, no kill) |
| frontend release/rollback without backend restart | ✅ | container IDs/start times identical before/after every frontend deploy/rollback |
| backend rolling/rollback without frontend rebuild | ✅ | `frontend_current_unchanged=true` on every backend run |
| old tab lazily loads old chunks | ✅ | 7/7 fe-r1 chunks after fe-r2 went live |
| versions, SHAs, digests, asset hashes traceable | ✅ | `DEPLOYMENT_STATE.json`, release manifests, tags |
| failed release recoverable; DB restore ≠ image rollback | ✅ | automatic frontend restore observed; drain-incomplete exit 10; rollback-backend refuses after schema change; restore is a separate isolated check |

## E. Operations
| Item | Status | Evidence |
| --- | --- | --- |
| volumes, log rotation, boot units, renewal, backup schedule | ✅ | named volumes `tauapi_*`; Docker json-file 20m×5; `/etc/logrotate.d/tauapi-nginx`; `tauapi-stack.service` + docker/nginx enabled; `tauapi-backup.timer` 03:30 daily |
| backup restored to isolated temp DB | ✅ | `restore-check.sh`: 38 tables, root user, setup row, app read OK |
| local vs off-site backup stated | ⚠️ | **local only** (`/var/backups/tauapi`); no off-site target configured → no disaster recovery for host loss |
| no secrets in logs/screenshots/git/report | ✅ | redacted access log format (path only); collect-evidence secret guard; screenshots use QA data |
| unconfigured external integrations listed | ✅ | HANDOFF.md §10 |
| no fake results / unverified claims / placeholders | ✅ | mock upstream results labelled QA-only; no CHANGE_ME values in rendered env |

Known limitations: NTP (outbound UDP 123 appears filtered; clock within 1 s of public HTTPS Date headers), upstream lint baseline (152 errors), single host (no HA).
