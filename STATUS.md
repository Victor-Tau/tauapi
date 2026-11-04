# STATUS

Current phase: P3/P4 (backend API-only verification, frontend independent build)

## Done
- P0 preflight (evidence/P0-preflight.md); nginx maintenance+ACME bootstrap live; LE cert issued (exp 2027-02-02)
- P1 pinned SHA verified, toolchains installed and checksum-verified, UPSTREAM_LOCK.json
- P2 frontend/backend repos imported (vendor/upstream + main + upstream/<sha> tag), bare remotes created

## Next
- Backend: full test run, Dockerfile/makefile/CI rewrite, image build
- Frontend: assetPrefix, release manifest, typecheck/lint/test/build baseline
- UI inventory + Minimalist Flat

## Blockers
- none

## Recovery entry
Read this file, then check `git -C /opt/newapi/{frontend,backend,ops} log -3`, `sudo docker ps`, `readlink /srv/newapi/current/frontend`, `/etc/nginx/sites-enabled/`.
