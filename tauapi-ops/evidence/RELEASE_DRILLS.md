# Release drills (real runs, 2026-11-04 UTC)

Raw logs: `evidence/raw/drill-*` (git-ignored). Scripts: `scripts/deploy-*.sh`, `scripts/rollback-*.sh`, `qa/release-drill.sh`.
QA = isolated stack (`TAUAPI_ENV=qa`, own DB/Redis, loopback :8443, real certificate, mock upstream). Production = api.victor-tau.xyz.

## Artefacts used (real, different, compatible)

| Unit | A | B | C |
| --- | --- | --- | --- |
| Frontend | `fe-r1-aade206` (pre-Flat, sha256 `33529454…3a6`) | `fe-r2-3097ff7` (Minimalist Flat, `fa75539c…0058`) | `fe-r3-0dab41b` (a11y + release notice, `269fb7fc…1d7c`) |
| Backend | `tauapi-be:53c0e999057f` (`sha256:74cfee86…f531`, be-r1) | `tauapi-be:a4231663776e` (`sha256:d5d09add…8639`, be-r2, new commit + version string) | – |

## Frontend

| Drill | Env | Result |
| --- | --- | --- |
| Deploy fe-r1 → current | prod, QA | assets published to `/_ui/fe-r1-aade206/`, atomic symlink switch, live verification passed, backend container IDs/start times unchanged |
| Deploy fe-r2 | prod, QA | same; `release/fe-r2-3097ff7` tag |
| Rollback fe-r2 → fe-r1 (no rebuild) | prod, QA | `rollback-frontend.sh` reused published artefact; `/_meta/ui-version.json` = fe-r1; backend unchanged |
| Re-deploy fe-r2 | prod | "versioned assets already published (identical)" – immutability check, no overwrite |
| Deploy fe-r3 | prod, QA | current = fe-r3; public smoke 42/42 |
| Failed verification → automatic restore | QA | one run hit an SPA redirect loop (stale slave, see DECISIONS 17); `deploy-frontend.sh` restored the previous release automatically (`deploy-failed` in release log) |
| Old tab lazy chunks | QA | tab opened on fe-r1; fe-r2 made current; client-side navigation loaded **7 lazy chunks from `/_ui/fe-r1-aade206/`, 0 failures**, no full reload |
| New-version notice | QA | tab on fe-r3, live switched; notice shown with Refresh action, **0 automatic reloads**, text typed in the search box kept |

## Backend rolling release (drained, one instance at a time)

Order: master out of upstream → drain (Nginx→backend established connections = 0) → replace → verify (container image ID, `/api/status`, DB-backed `/api/setup.status`, `server_address`, JSON 404) → back in → same for slave.

| Drill | Env | Drain | New-request probe (every 0.2 s) | Streams during release |
| --- | --- | --- | --- | --- |
| be-r1 → be-r2 | QA | master 15 s (waited for live SSE), slave 2 s | 107 ok / **0 failed** | SSE `mock-slow-20`: 20 chunks at 1.08 s … 20.09 s, `[DONE]` at 20.11 s (on the drained instance, not cut). WS: 101, 22 events over 20 s, clean client close |
| be-r2 → be-r1 (rollback) | QA | master 17 s, slave 2 s | – | SSE 20/20 + `[DONE]`; WS 22 events, clean close |
| be-r1 → be-r2 | prod | 2 s / 2 s | 59 ok / **0 failed** | (no test key in prod; probe only) |
| be-r2 → be-r1 (rollback) | prod | 2 s / 2 s | 54 ok / **0 failed** | – |
| be-r1 → be-r2 (final) | prod | 2 s / 2 s | 57 ok / **0 failed** | – |

After every run: exactly one master and one slave on the target image; frontend `current` unchanged; `release/be-<commit>` tag recorded.

## Long-connection boundary (WS longer than the drain window)

QA, `--ws 150 --drain 30`: master taken out of the upstream, the 150 s WebSocket kept it at 1 connection for 30 s → `deploy-backend.sh` **exited 10 "drain incomplete … NOT stopping it"**, recorded `backend-release-paused.json`, left master running (serving only its existing connection) and slave serving all new traffic. The WS ran its full 150 s (152 events, clean close). The operator then restored the upstream (`set-upstream.sh both`). Nothing was force-killed.

Capability statement:
- New requests switch instances with no failed requests (measured above).
- Bounded SSE streams that finish within the drain window complete normally.
- Long-lived WebSockets are **not migrated**: Go `Shutdown` does not wait for hijacked connections, so the script refuses to stop an instance that still holds them and reports instead. Clients of a WS that outlives the window must reconnect after the operator finishes the release; no session resumption is promised.
- Nginx `worker_shutdown_timeout 660s` bounds how long old workers keep connections after reloads (longer than the backend's 120 s shutdown window).

## Data

- Pre-release backup taken automatically by `deploy-backend.sh` (pg_dump -Fc).
- `restore-check.sh` restored the latest prod dump into a throwaway tmpfs PostgreSQL on an internal network: 38 tables, 1 root user, setup row present, and the backend image read the restored DB (`setup.status=true`, `server_address=https://api.victor-tau.xyz`).
- No schema change between be-r1 and be-r2 → rollback is symmetric. Database restore is documented as a separate, non-automatic operation.
