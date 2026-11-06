> Historical record: 2026-11-04 deployment/bootstrap scope, retained at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f.
> Current maintenance entry: [active documentation](../docs/ai/INDEX.md).
> GOAL.md references and split-repository phases are historical, not current policy.

# PLAN — tauapi

Source of truth: GOAL.md (v1.0, 2026-11-04). Phases and gates follow GOAL §18.

| Phase | Scope | Depends on | Gate |
| --- | --- | --- | --- |
| P0 Discovery | host facts, sudo, ports, DNS, egress | – | evidence/P0-preflight.md |
| P1 Source | pinned SHA verify, toolchain lock, read AGENTS rules | P0 | UPSTREAM_LOCK.json |
| P2 Git split | frontend/backend/ops repos, vendor/upstream, bare remotes, bundles | P1 | distinct git-common-dir, tags, bundles verified |
| P3 Backend | API-only main/router, tests, Dockerfile/makefile/CI w/o web | P2 | clean clone: go build . / go test ./... ; image digest |
| P4 Frontend base | fixture relocation, plugin scripts out, assetPrefix /_ui/<id>/, manifest | P2 | clean clone: bun install/typecheck/lint/test/build |
| P5 Full UI | Minimalist Flat tokens + shared layers + every feature; UI_INVENTORY.csv; screenshots | P4 | inventory all rows checked w/ evidence |
| P6 Infra | compose (pg16, redis, master/slave on 127.0.0.1), secrets, nginx maintenance | P3 | healthy stack, no public DB ports |
| P7 TLS+init | certbot webroot, renew dry-run, loopback-only admin bootstrap, open site | P6 | public HTTPS + smoke |
| P8 Release | deploy/rollback frontend + backend rolling, SSE/WS drain, old chunk | P5,P7 | evidence/release-drills.md |
| P9 Ops | backup/restore-check, logrotate, timers, HANDOFF.md | P8 | GOAL §19 checklist |

Serial-only operations (deploy lock /run/lock/tauapi-deploy.lock): DB migration, nginx switch, current symlink, rollback.
