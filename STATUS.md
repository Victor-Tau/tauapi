# STATUS (TauAPI)

Updated: 2026-11-04 (UTC)

Current phase: P5 (UI verification) / P8 (release drills)

## Done
- P0 preflight (evidence/P0-preflight.md)
- P1 pinned upstream ba5f7367 verified; Go 1.26.10 / Bun 1.4.4 checksum-verified
- P2 repos tauapi-fe / tauapi-be / tauapi-ops with vendor/upstream, main, upstream/<sha> tags, bare remotes in /var/lib/tauapi/git
- P3 backend API-only (no go:embed, JSON 404 fallback after plugin dispatcher); root 47 pkgs + relaykit + tokenkit tests pass; image tauapi-be:53c0e999057f
- P4 frontend standalone (fixture snapshot, plugin scripts moved, /_ui/<id>/ prefix); typecheck/test/build pass; lint = upstream baseline (152 errors, identical list)
- P6 prod stack (pg16.15, redis7.4.12 pinned digests; master 127.0.0.1:3001, slave :3002); secrets /etc/tauapi (0600)
- P7 LE cert (exp 2027-02-02), renew dry-run OK, admin initialised over loopback, site opened (live); public auth smoke passed
- P8 partial: frontend deploy fe-r1 (prod+QA), SSE/WS through Nginx verified in QA with mock upstream
- P9 partial: backup + isolated restore-check passed; backup timer, stack boot unit, nginx logrotate, certbot timer

## In progress
- Minimalist Flat source changes (173 files) under test; then commit, build fe-r2, screenshots (QA), deploy

## Next
- Backend rolling release + rollback drill (QA then prod), SSE/WS drain evidence
- Frontend rollback drill, old-tab lazy chunk test
- HANDOFF.md, DEPLOYMENT_STATE.json, evidence summaries, bundles

## Blockers
- none

## Recovery entry
Read this file, then `git -C /opt/tauapi/{tauapi-fe,tauapi-be,tauapi-ops} log -3`, `sudo docker ps`,
`readlink /srv/tauapi/current/frontend`, `cat /srv/tauapi/state/*`, `ls /etc/nginx/sites-enabled/`.
