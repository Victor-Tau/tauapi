# Current-source task routing inputs

Status: **migration mapping input**, not a claim that the proposed documentation system is installed.
Baseline: `ebc4cebd9c7edee2743700310fd877984ed349eb` in `Victor-Tau/tauapi`; inspected on 2026-11-06.
All repository paths below exist at that baseline. Source inspection and path checks were performed; the listed validations were not run.

## Entry rules and evidence limits

- Read the current root entry in this order: `AGENTS.md`, `map.md`, `tauapi-ops/STATUS.md`.
- For frontend work, read `tauapi-fe/CLAUDE.md`, `tauapi-fe/AGENTS.md`, and the currently required `tauapi-fe/UPSTREAM_ROOT_AGENTS.md`; apply the split-path notice to stale upstream names.
- For backend work, read `tauapi-be/CLAUDE.md`, `tauapi-be/AGENTS.md`, and `tauapi-be/REPOSITORY_SPLIT.md`; load additional mandatory rules when the task matches their scope.
- The selective reads below follow those current entry requirements. They do not waive a mandatory read, security rule, or database verification requirement.
- The current entry points include Chinese and stale material. Replacing them with an English routing layer is migration work; these mappings do not silently redefine existing authority.
- `tauapi-ops/STATUS.md`, `tauapi-ops/DEPLOYMENT_STATE.json`, and `tauapi-ops/evidence/SUMMARY-prod.md` record past observations. They do not verify production now.
- Validation means observing a result for the delivered revision and named environment. Historical counts, a planned command, or an unexecuted test target are not passing evidence.

## 1. Add a SPA page or change a page URL

- Ordered reads: frontend entry, then `tauapi-ops/ROUTE_CONTRACT.json`, `tauapi-fe/src/lib/legacy-route.ts`, and the nearest existing route and feature.
- Concrete trace: `tauapi-fe/src/routes/_authenticated/channels/index.tsx` to `tauapi-fe/src/features/channels/index.tsx`; inspect `tauapi-fe/src/components/layout/lib/sidebar-view-registry.ts` when navigation changes.
- Cross-component trace: file routes and generated `tauapi-fe/src/routeTree.gen.ts` must agree with `tauapi-ops/scripts/generate-nginx.py` and the registered SPA prefixes; unknown root URLs otherwise reach the API-only fallback.
- Validation targets: affected feature tests and frontend typecheck; `tauapi-fe/src/lib/legacy-route.test.ts` or `tauapi-fe/src/hooks/__tests__/sidebar-config.test.tsx` when their behavior changes.
- Deployment validation: test direct navigation and browser reload at the new URL, HTML versus JSON content type, reserved namespaces, and missing-asset 404 behavior; extend relevant cases in `tauapi-ops/scripts/smoke.sh`.
- Documentation impact: update the existing route contract when its page namespace changes, the navigation entry when applicable, and the module/contract records created during migration. Regenerate the route tree using the existing frontend tooling.
- Boundary: the generator's optional static plugin scan is not proof that every page and backend route is covered; see the limitations below.

## 2. Diagnose sign-out or repeated login after page refresh

- Ordered reads: both component entries, `tauapi-be/docs/authentication.md`, `tauapi-fe/src/lib/http-client.ts`, then `tauapi-fe/src/lib/auth-session.ts` and `tauapi-fe/src/stores/auth-store.ts`.
- Frontend trace: a request or bootstrap enters `refreshAuthentication`; a 401 may retry once after refresh, while refresh outcomes distinguish anonymous, out-of-sync, and retryable failures.
- Backend trace: `/api/user/auth/refresh` in `tauapi-be/router/api-router.go` uses the origin guard in `tauapi-be/middleware/auth_origin.go`, then `RefreshAuth` in `tauapi-be/controller/auth_session.go`, `RefreshLoginSession` in `tauapi-be/service/auth_session.go`, and rotation in `tauapi-be/model/user_session.go`.
- Validation targets: `tauapi-fe/src/lib/auth-session.test.ts`, `tauapi-be/middleware/auth_origin_test.go`, `tauapi-be/controller/auth_session_test.go`, `tauapi-be/service/auth_session_test.go`, and `tauapi-be/model/user_session_test.go`, selected by the failing behavior.
- Cross-instance validation: inspect `tauapi-ops/qa/session-restart-check.py` and `tauapi-ops/scripts/smoke-auth.py`; run applicable integration checks only in the intended environment with authorized test credentials.
- Documentation impact: record the reproduction, root cause, and regression; update `tauapi-be/docs/authentication.md` if the auth contract changes, and the corresponding module/contract records during migration.
- Boundary: preserve cookie origin checks, rotation and replay handling, cross-tab coordination, and retryable failure behavior; changing frontend expiry alone does not establish a fix.

## 3. Change billing, quota settlement, or displayed model prices

- Ordered reads: backend entry and `tauapi-be/.agents/rules/billing.md`; add the frontend entry and `tauapi-fe/.agents/rules/billing.md` when browser behavior is affected, then `tauapi-be/pkg/billingexpr/expr.md`.
- Code trace: inspect `tauapi-be/relay/request_billing.go`, `tauapi-be/service/billing_session.go`, and `tauapi-be/service/billing.go`; trace browser calculations through `tauapi-fe/src/features/pricing/lib/billing-expression/README.md` and the relevant pricing implementation.
- Shared data: compare `tauapi-be/pkg/billingexpr/testdata/frontend_simulation.json` with `tauapi-fe/testdata/contracts/frontend_simulation.json` and the provenance in `tauapi-fe/UPSTREAM.json`.
- Validation targets: `tauapi-be/pkg/billingexpr/billingexpr_test.go`, `tauapi-be/pkg/billingexpr/settle_clamp_test.go`, `tauapi-fe/src/features/pricing/lib/__tests__/billing-expression.test.ts`, plus affected settlement or UI tests.
- Expand validation when warranted: concurrent settlement, duplicate completion, failure refunds, and real database behavior according to the billing rule; a browser snapshot comparison alone cannot prove settlement correctness.
- Documentation impact: update changed expression semantics and contract provenance together; record which business invariant each regression protects.
- Boundary: do not independently alter the frontend snapshot to make tests pass; preserve its source relationship and follow the current billing rules.

## 4. Add or modify an upstream provider or protocol conversion

- Ordered reads: backend entry, `tauapi-be/relaykit/README.md`; add `tauapi-be/tokenkit/README.md` if counting changes and billing rules if usage or quota can change.
- Code trace: `tauapi-be/router/relay-router.go` to `tauapi-be/controller/relay.go`, `tauapi-be/middleware/distributor.go`, `tauapi-be/relay/relay_adaptor.go`, then the affected provider adaptor or converter.
- Cross-component trace: inspect `tauapi-fe/src/features/channels/api.ts` and channel configuration only when provider options or API shapes change; inspect the route contract for a new public namespace.
- Validation targets: affected provider tests, `tauapi-be/relaykit/relayconvert/golden_test.go` for conversion contracts, and `tauapi-be/tokenkit/tokenkit_test.go` when counting changes.
- Independent checks: run `GOWORK=off go build ./...` inside each changed independent module, plus its affected tests; a root-module build is not sufficient.
- Documentation impact: record supported protocol behavior, error and streaming semantics, module boundaries, and any changed public contract; preserve upstream attribution.
- Boundary: transport, host authentication, persistence, and settlement remain host concerns; do not create a reverse dependency from an independent module to the host.

## 5. Add or change a JavaScript task plugin

- Ordered reads: backend entry, `tauapi-be/docs/plugin-api/v1.md`, `tauapi-be/docs/plugin-api/v1.schema.json`, `tauapi-be/docs/plugin-api/v1.d.ts`, then billing rules if task settlement is affected.
- Code trace: the selected plugin under the existing task-plugin tree, `tauapi-be/plugins/embed.go`, `tauapi-be/pkg/jsplugin/registry.go`, `tauapi-be/pkg/jsplugin/routing.go`, and `tauapi-be/router/task-plugin-protocol-router.go`.
- Concrete reference: `tauapi-be/plugins/tasks/google/plugin.js` is an existing example, not a mandatory template for unrelated providers; task settlement continues through `tauapi-be/service/task_billing.go`.
- Validation targets: the affected plugin tests, `tauapi-be/pkg/jsplugin/routing_test.go`, `tauapi-be/router/plugin_router_test.go`, and `tauapi-be/service/task_billing_test.go`; plugin lint/format commands are defined in `tauapi-be/makefile`.
- Cross-component check: review the new route against `tauapi-ops/ROUTE_CONTRACT.json`; supplement static conflict scanning with host routing and representative HTTP behavior tests.
- Documentation impact: update API schema/types/docs together if the plugin API changes; update route ownership, billing semantics, and provenance where affected.
- Boundary: a plugin may use computed or dynamic routes that the Nginx generator's regex scan cannot enumerate.

## 6. Change a database model, migration, locking, or database dependency

- Ordered reads: backend entry's database requirements, `tauapi-be/model/main.go`, `tauapi-be/model/migration_dialector.go`, and `tauapi-be/model/locking.go`; add affected auth or billing rules.
- Code trace: initialization and migration into the changed model and its callers; inspect `tauapi-ops/scripts/deploy-backend.sh` and `tauapi-ops/scripts/rollback-backend.sh` for mixed-version and rollback consequences.
- Validation targets: relevant existing migration tests such as `tauapi-be/model/user_session_migration_test.go`, `tauapi-be/model/token_migration_test.go`, and `tauapi-be/model/locking_test.go`.
- Required integration scope: real SQLite, MySQL, and PostgreSQL as required by the current backend rules; fresh creation and representative upgrades, repeated startup for idempotency, and affected separate-log-database behavior.
- Release check: verify compatibility while old and new instances coexist; explicitly decide whether the previous application can run against the resulting schema.
- Documentation impact: record schema changes, tested versions, migration evidence, and rollback limitations; historical `tauapi-ops/DEPLOYMENT_STATE.json` does not describe a new release.
- Boundary: the current release writer omits `schema_changed`, while the rollback reader defaults it to false; an absent field is not evidence of safe rollback.

## 7. Release independently or diagnose stale frontend assets after release

- Ordered reads: `tauapi-ops/DECISIONS.md`, the relevant build/deploy/rollback scripts, `tauapi-fe/rsbuild.config.ts`, and `tauapi-fe/src/hooks/use-release-update-notice.ts` for frontend incidents.
- Frontend trace: `tauapi-ops/scripts/build-frontend.sh` to `tauapi-ops/scripts/deploy-frontend.sh`, `tauapi-ops/scripts/lib-frontend.sh`, and `tauapi-ops/scripts/prune-frontend.sh`; preserve immutable version URLs and old-tab assets.
- Backend trace: `tauapi-ops/scripts/build-backend.sh` to `tauapi-ops/scripts/deploy-backend.sh`, connection draining, instance verification, and the rollback preconditions above.
- Validation targets: `tauapi-ops/qa/old-tab-drill.mjs`, `tauapi-ops/qa/notice-check.mjs`, `tauapi-ops/qa/release-drill.sh`, `tauapi-ops/qa/ws-probe.py`, and relevant smoke cases in an isolated, prepared QA environment.
- Documentation impact: collect fresh release observations with `tauapi-ops/scripts/collect-evidence.sh` when authorized; update English status and the Chinese human handoff using actual results and preserve historical evidence.
- Existing gap: frontend deployment logs `compatible_backend` but does not enforce a compatibility decision; a commit-shaped label is not a semantic version ordering.
- Boundary: `tauapi-ops/docs/DEPLOYMENT.md` is a fresh-host guide with unverified sequencing; reconcile its early slave-start instruction with the initialization guard in `tauapi-ops/scripts/bootstrap-stack.sh` before using it.

## 8. Upgrade from pinned upstream without losing local behavior or rules

- Ordered reads: `tauapi-ops/DECISIONS.md`, `tauapi-ops/UPSTREAM_LOCK.json`, both component `UPSTREAM.json` records, `tauapi-ops/scripts/import-upstream.py`, and `tauapi-ops/scripts/sync-upstream.sh`.
- Code trace: the importer maps upstream files into vendor snapshots; sync merges those snapshots into component subtrees on an upgrade branch. Inspect changed auth, schema, billing, route, and imported instruction files before accepting conflicts.
- Rule provenance: compare `tauapi-fe/UPSTREAM_ROOT_AGENTS.md`, `tauapi-fe/CLAUDE.md`, and `tauapi-be/CLAUDE.md` against the intended current entry rules; imported upstream paths can be stale after splitting.
- Validation targets: both component builds/tests, the billing snapshot comparison, applicable task-specific checks above, and standalone module checks. `tauapi-ops/scripts/verify-independent-builds.sh` currently exports `main`, so it must not be used as evidence for an unmerged upgrade revision.
- Revision discipline: use an explicitly identified candidate revision for independent subtree checks; record exact source SHA, export SHA, toolchain, commands, and results.
- Documentation impact: update verified upstream provenance and affected contracts, resolve superseded instructions, and record the upgrade decision. Do not rewrite old evidence as if it described the new revision.
- Boundary: `tauapi-be/.github/workflows/ci.yml` is nested below the monorepo root; its existence does not mean that root GitHub Actions or branch protection enforce these checks.

## Known coverage limits to preserve in the migration

- `tauapi-ops/scripts/generate-nginx.py` uses explicit page lists. It does not derive a complete route inventory from the frontend or Go server.
- Its `check_plugin_conflicts` runs only with `--check-plugins`, scanning JS/MJS/TS text for literal `path: '/...'` or double-quoted equivalents. It does not parse computed route values, enumerate Go router registrations, or prove method-aware route coverage.
- Current generation calls in the site-mode and frontend deployment scripts do not pass that optional plugin check. Generator success alone is therefore insufficient acceptance evidence.
- Match regression tests to changed behavior. Run broader checks to cover concrete affected contracts or mandatory gates; do not invent passing results, claim live state from snapshots, or create empty tests just to satisfy a document checklist.
