# TauAPI

Front/back-end split distribution of [QuantumNous/new-api](https://github.com/QuantumNous/new-api)
(pinned upstream `ba5f7367797566175a6cd97a748d430af3602a01`), kept as one repository for distribution.
New API / QuantumNous branding, licences and attribution are preserved (see each part's LICENSE/NOTICE).

| Directory | Part | Build | Release unit |
| --- | --- | --- | --- |
| `tauapi-fe/` | React 19 + Rsbuild frontend (upstream `web/`), Minimalist Flat UI | `bun install --frozen-lockfile && bun run build` (inside `tauapi-fe/`) | versioned static archive served under `/_ui/<release>/` |
| `tauapi-be/` | API-only Go backend (upstream minus `web/`, `electron/`) | `go build .` (inside `tauapi-be/`) | Docker image `tauapi-be:<commit12>` |
| `tauapi-ops/` | deployment, Nginx, release/rollback, backup, QA, evidence, handoff | shell/python scripts | – |

The two parts still build, test, ship and roll back independently: the release scripts export
only `main:tauapi-fe` or `main:tauapi-be` (`git archive`) as the build context, so neither build can
read the other directory.

- System map (architecture, endpoints, file tree): [`map.md`](map.md)
- Operations handoff: [`tauapi-ops/HANDOFF.md`](tauapi-ops/HANDOFF.md)
- Frontend rules: [`tauapi-fe/AGENTS.md`](tauapi-fe/AGENTS.md) (read `tauapi-fe/UPSTREAM_ROOT_AGENTS.md` first)
- Backend rules: [`tauapi-be/AGENTS.md`](tauapi-be/AGENTS.md)

Branches: `main` (all customisations); `vendor/upstream-fe`, `vendor/upstream-be` (raw upstream imports
in split layout, merged into the subdirectories with `tauapi-ops/scripts/sync-upstream.sh`).
