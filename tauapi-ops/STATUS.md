# STATUS (TauAPI)

Updated: 2026-11-04 (UTC)

Current phase: **complete** (P0–P9). Handoff: `HANDOFF.md`; acceptance: `evidence/ACCEPTANCE.md`.

## Live
- https://api.victor-tau.xyz (public), frontend `fe-r4-db3916f`, backend master+slave `tauapi-be:db3916f928c8` (both `1.0.0+…db3916f928c8`; rollback targets fe-r3-0dab41b / tauapi-be:a4231663776e)
- public smoke 42/42; auth flow OK; backups daily (local only)

## Done
- P0 preflight · P1 pinned upstream + toolchains · P2 repos (merged 2026-11-04 into one monorepo `/opt/tauapi`, remote `/var/lib/tauapi/git/tauapi.git`; split repos archived as bundles)
- P3 API-only backend (clean clone in Go container, no Node/Bun: build OK, 47+9+1 test pkgs OK)
- P4 standalone frontend (clean clone, no Go: 2465 tests, build OK), /_ui/<release>/ assets, release notice
- P5 Minimalist Flat (173+ files), 77-row UI inventory, 230/231 captures, overlays 17/17, contrast 16/16, keyboard, zh@200%, setup wizard
- P6 pg16/redis7.4 pinned, master/slave on loopback, secrets 0600 · P7 LE cert + dry-run, loopback admin init, opened
- P8 frontend deploy/rollback/old-tab/notice; backend rolling deploy/rollback (QA with SSE/WS, prod probe 0 failures), WS boundary pause
- P9 backup + isolated restore, timers, logrotate, boot unit, evidence, HANDOFF

## Pending (2026-11-04)
- own release channel deployed (DECISIONS #20, HANDOFF §8.1); `Victor-Tau/tauapi` is public but has **no Releases yet** → admin sees "no newer version". Next: push tag `v1.0.0` to `github` and publish a Release (no credentials for the `github` remote on this host).
- `build-frontend.sh` needs bun on PATH (typecheck calls `bun`); not yet fixed in the script.

## Open items (non-blocking, need user action)
- off-site backup target · outbound UDP 123 for NTP · optional removal of `newapi_*` volumes · external integrations (provider keys, SMTP, OAuth, payment)

## Recovery entry
Read this file and HANDOFF.md, then `git -C /opt/tauapi log --oneline -5`, `sudo docker ps`,
`readlink /srv/tauapi/current/frontend`, `sudo cat /srv/tauapi/state/*`, `ls /etc/nginx/sites-enabled/`.
