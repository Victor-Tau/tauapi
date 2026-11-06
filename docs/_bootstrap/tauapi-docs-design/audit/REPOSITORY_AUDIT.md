# TauAPI Repository Documentation Audit

## Baseline and evidence limits

- Repository: `https://github.com/Victor-Tau/tauapi`.
- Inspected commit: `ebc4cebd9c7edee2743700310fd877984ed349eb`.
- Commit timestamp: `2026-11-04T16:10:20Z`; audit date: `2026-11-06`.
- Scope: read-only source, documentation, configuration, and test inspection; fixture byte/hash comparison.
- No application tests, builds, deployment commands, production queries, or live-host checks were executed.
- This is an audit and a set of proposed documentation controls, not a claim that those controls exist today.

Evidence labels used below:

- **Observed**: directly present in the inspected commit or established by a local file comparison.
- **Inferred**: an implication of observed source, without reproducing runtime behavior.
- **Unverified**: requires execution, deployment access, service configuration, or additional evidence.
- Priorities describe documentation/control work: **P0** before relying on unattended operations; **P1** for the first implementation; **P2** for subsequent refinement.

## Priority findings

| Priority | Evidence | Finding and implication |
| --- | --- | --- |
| P0 | Observed + inferred | The deployment runbook starts a slave before its script's initialization prerequisite is satisfied. A fresh installation following the documented order can stop before the later admin initialization step. See the operations findings below. |
| P0 | Observed | Frontend/backend compatibility is logged, not enforced, in `deploy-frontend.sh`; backend rollback reads a schema flag that the normal deployment record does not write. Documentation must describe these gaps explicitly. |
| P1 | Observed | Backend instructions retain nonexistent `web/` and `electron/` navigation and descriptions of separate repositories after the monorepo conversion. [S1] [S2] [S3] |
| P1 | Observed + inferred | The inspected tree has no root `.github/workflows/` directory. Inherited workflows under component directories do not establish a monorepo root validation gate; their paths also assume a component checkout root. [S4] |
| P1 | Observed | Database rules require real SQLite, MySQL, and PostgreSQL verification, while database tests can skip missing MySQL/PostgreSQL DSNs. A successful test process is insufficient evidence of the required matrix. [S1] [S6] |
| P1 | Observed | The backend contains three Go modules. Independent library checks are required; the existing `make test` explicitly enters all three modules. [S5] [S7] [S8] [S9] |
| P1 | Observed | Important technical references are Chinese or mixed-language, including authentication, billing expressions, and library READMEs. Audience classification and English canonical references are needed. [S10] [S11] |
| P1 | Observed + inferred | Upstream imports include active component agent instructions. A clean subtree merge can introduce policy changes without a textual conflict. Governance changes need a separate review/check category. [S19] [S20] |
| P2 | Observed | Existing billing rules, plugin contract files, authorization coverage tests, and API-only fallback tests are valuable foundations. Preserve and link them rather than replacing them with generic summaries. [S12] [S13] [S14] [S15] |

## Six proposed backend documentation domains

These are proposed navigation domains, not existing module-document names. Business behavior crosses Go package boundaries.

| Domain | Primary source entry points | Typical path to follow |
| --- | --- | --- |
| Authentication and authorization | `middleware/auth.go`, `service/auth_session.go`, `service/auth_token.go`, `service/authz/`, `model/user_session.go` | API route -> dashboard credential classification -> session/PAT validation -> permission/proof -> persistent state/cache. |
| Relay and provider routing | `router/relay-router.go`, `middleware/distributor.go`, `controller/relay.go`, `relay/` | Route/auth -> channel selection -> `controller.Relay` -> provider handler/conversion -> stream/response -> usage settlement. |
| Billing and quota | `relay/request_billing.go`, `service/billing_session.go`, `service/task_billing.go`, `common/quota_math.go`, `pkg/billingexpr/` | Validate quantities -> `PrepareRequestBilling` -> pre-consume -> actual usage -> settle/refund -> accounting log. |
| Task plugins | `docs/plugin-api/v1.md`, `pkg/jsplugin/`, `router/plugin-router.go`, `service/task_polling.go`, `plugins/tasks/` | Manifest validation -> native route or host protocol -> submission -> polling/immediate completion -> guarded state transition -> settlement. |
| Persistence and migrations | `model/main.go`, `model/locking.go`, `model/*migration*.go`, `common/database.go` | Select primary/log database -> master migration -> model operation/transaction -> cache -> compatibility verification. |
| Independent libraries | `relaykit/`, `tokenkit/`, and each module's `go.mod` | Host input preparation -> protocol conversion or token counting -> host transport/authorization/billing; no reverse dependency on the host module. |

For later expansion, separate authorization/API management from login/session behavior, and separate RelayKit from TokenKit when their navigation pages become too large.

## Five contracts the design must preserve

1. **Authentication boundaries.** Browser sessions, personal access tokens, and relay API keys have different semantics. Every dashboard route needs an explicit PAT policy or justified exemption; authorization remains server-side. Existing route-coverage tests are a concrete verification anchor. [S10] [S14]
2. **Billing safety and lifecycle.** Preserve bounded request quantities, centralized checked quota conversion, administrator overrides, pre-consume/settle/refund semantics, saturation audit markers, image payload counting, and cancellation behavior. Read the existing billing rules in full for matching tasks. [S12]
3. **API-only routing and plugin precedence.** Unmatched requests reach dynamic plugin routing before uncached JSON 404; they must not fall back to SPA HTML. Preserve stream flushing and keep fallback cache headers off successful plugin responses. [S15] [S16]
4. **Data compatibility.** The primary database supports SQLite, MySQL, and PostgreSQL; ClickHouse is a separate log-database option. Preserve master migration behavior, shared locking helpers, fresh/upgrade/idempotency checks, and application/schema compatibility. [S1] [S17]
5. **Independent builds and explicit integration contracts.** RelayKit and TokenKit remain independently buildable; frontend/backend billing semantics and plugin Markdown/schema/TypeScript contracts must evolve together. Separate builds do not imply unrestricted version compatibility. [S7] [S8] [S9] [S13]

Do not promote intended invariants into proven guarantees: for example, process-local settlement guards and task CAS tests do not by themselves prove crash-safe, cross-system exactly-once accounting.

## Available verification commands: inspected, not executed

| Working directory | Command | Meaning and limitation |
| --- | --- | --- |
| `tauapi-be` | `GOWORK=off go vet ./...` | Root-module static checks; not a replacement for nested-module checks. |
| `tauapi-be` | `GOWORK=off go build ./...` | Root-module build only. |
| `tauapi-be` | `make test` | Existing target runs root, RelayKit, and TokenKit tests separately with `GOWORK=off`. [S5] |
| `tauapi-be/relaykit` | `GOWORK=off go build ./...` | Independent RelayKit build. |
| `tauapi-be/tokenkit` | `GOWORK=off go build ./...` | Independent TokenKit build. |
| `tauapi-be` | `GOWORK=off go test ./router -run TestAccessTokenRouteRulesCoverEveryDashboardRoute` | Existing dashboard PAT route-declaration coverage test. [S14] |
| `tauapi-be` | `GOWORK=off go test ./pkg/billingexpr -run TestFrontendSimulationContract` | Existing Go evaluation against the backend fixture copy. [S18] |
| `tauapi-fe` | `bun run test src/features/pricing/lib/__tests__/billing-expression.test.ts` | Existing Vitest script and frontend billing test file. [S21] [S22] |
| `tauapi-be` | `make lint-plugins` / `make format-plugins-check` | Existing plugin tooling targets; require their declared toolchain/dependencies. [S5] |

Toolchain declarations are Go `1.26.10` for the host, `1.25.1` for RelayKit, and `1.26` for TokenKit at this baseline. [S7] [S8] [S9]
Production currently using one database must not silently narrow the source project's supported database contract.
The inherited backend workflow specifies `GOWORK=off` and three-module checks but does not configure database services or required database DSNs. [S4]
`model/token_migration_test.go` skips MySQL/PostgreSQL cases when `TEST_MYSQL_DSN` / `TEST_POSTGRES_DSN` are absent; other migration tests use the same pattern. [S6]

**Proposed result model:** use `passed`, `failed`, and `blocked` for required checks; record `skipped` separately with its reason.
A skipped required database check yields `blocked`, not `passed`; an explicitly inapplicable check can be omitted with an impact explanation.
Record exact commands, working directories, database versions, exit status, and relevant skips; never copy historical success counts as current evidence.

## Billing fixture copies and drift detection

- **Observed:** the frontend imports `testdata/contracts/frontend_simulation.json`; the Go test reads `pkg/billingexpr/testdata/frontend_simulation.json`. They are two physical copies. [S18] [S21]
- **Observed:** both copies are 9,523 bytes and have SHA-256 `1569342ecacee420addba7b777c1d87a6594cb72ff0acd667d779ce40b8335e3` in the inspected checkout.
- **Observed:** the hash matches `contract_fixtures` in both component `UPSTREAM.json` files. [S23] [S24]
- **Observed:** `sync-upstream.sh` prints a manual comparison reminder; it does not execute the equality or semantic checks. [S20]
- **Proposed:** check byte equality in root CI, then execute both existing semantic suites against the synchronized cases.
- **Proposed:** keep the copies because component builds are isolated; define one authored contract source and an explicit synchronization operation.
- **Proposed:** preserve `UPSTREAM.json` as import provenance. Track local contract revisions separately instead of rewriting an upstream hash to impersonate a local change's origin.
- **Unverified:** neither evaluator suite was executed in this audit; equal files do not prove equal implementation behavior.

## Independently inspected operations findings

### Fresh bootstrap ordering

- **Observed:** `DEPLOYMENT.md` phase 4 invokes `bootstrap-stack.sh --with-slave`; admin initialization is deferred until phase 6. [S25]
- **Observed:** `bootstrap-stack.sh` refuses slave startup when `/api/setup` is not initialized and instructs the operator to initialize the admin, restart master, then rerun with `--with-slave`. [S26]
- **Inferred:** for a genuinely fresh database, following the documented sequence can stop with exit 3 at the early slave step.
- **Proposed:** document and verify a master-only bootstrap, admin initialization, master restart, and subsequent slave startup sequence. Re-check TLS/frontend prerequisites before making a runnable runbook claim.

### Frontend/backend compatibility

- **Observed:** `deploy-frontend.sh` line 43 logs `compatible_backend` beside the running backend version. No compatibility rejection is implemented at that comparison. [S27]
- **Inferred:** presence of the manifest field is not evidence that incompatible combinations are blocked.
- **Proposed:** define a precise compatibility contract and implement a check before publishing/switching the frontend; distinguish observed compatibility metadata from enforcement.

### Schema-aware backend rollback

- **Observed:** `rollback-backend.sh` reads `.schema_changed // false` from `backend-release.json` and conditionally requires `--allow-schema-change-reviewed`. [S28]
- **Observed:** `deploy-backend.sh` writes that record without a `schema_changed` field; its direct `--rollback` entry also has no equivalent schema gate. [S29]
- **Inferred:** a missing value follows the false branch, so the existing wrapper does not establish reliable schema-aware rollback protection.
- **Proposed:** require explicit migration/compatibility metadata, treat unknown state as blocked, and share the same validation across rollback entry points.
- **Unverified:** no deployment, rollback, or fresh installation was attempted; no production damage or current outage is asserted.

## Upstream instruction ownership

The importer maps upstream root `CLAUDE.md` directly to frontend `CLAUDE.md`; its `web/` mapping also imports frontend `AGENTS.md`.
For the backend, only `web/` and `electron/` are excluded, so `AGENTS.md`, `CLAUDE.md`, and `.agents/` remain imported. [S19]
The sync script performs subtree merges and leaves an upgrade branch for review; it does not run a governance-content gate. [S20]
**Proposed:** preserve upstream instruction provenance, make TauAPI's effective local entry policy explicit, and flag all instruction/import-map changes during upgrades.
Do not claim that a merge conflict is required for an upstream rule to change, or that a successful merge proves policy compatibility.

## Pinned source references

[S1]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/AGENTS.md
[S2]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/CLAUDE.md
[S3]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/REPOSITORY_SPLIT.md
[S4]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/.github/workflows/ci.yml
[S5]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/makefile
[S6]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/model/token_migration_test.go
[S7]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/go.mod
[S8]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/relaykit/go.mod
[S9]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/tokenkit/go.mod
[S10]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/docs/authentication.md
[S11]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/pkg/billingexpr/expr.md
[S12]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/.agents/rules/billing.md
[S13]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/docs/plugin-api/v1.md
[S14]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/router/access_token_scope_test.go
[S15]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/router/plugin_router_test.go
[S16]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/router/main.go
[S17]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/model/main.go
[S18]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/pkg/billingexpr/billingexpr_test.go
[S19]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-ops/scripts/import-upstream.py
[S20]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-ops/scripts/sync-upstream.sh
[S21]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-fe/src/features/pricing/lib/__tests__/billing-expression.test.ts
[S22]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-fe/package.json
[S23]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-fe/UPSTREAM.json
[S24]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-be/UPSTREAM.json
[S25]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-ops/docs/DEPLOYMENT.md
[S26]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-ops/scripts/bootstrap-stack.sh
[S27]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-ops/scripts/deploy-frontend.sh
[S28]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-ops/scripts/rollback-backend.sh
[S29]: https://github.com/Victor-Tau/tauapi/blob/ebc4cebd9c7edee2743700310fd877984ed349eb/tauapi-ops/scripts/deploy-backend.sh
