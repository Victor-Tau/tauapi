# Implement the TauAPI documentation system

## Purpose and scope

Build a durable documentation system for autonomous Claude Code maintenance of TauAPI. The system must route an agent from a small policy entry point to the relevant domain, cross-component contracts, source code, tests, and change evidence. AI-facing content is English. Human-facing explanations are plain Simplified Chinese.

This is a proposed implementation specification, not an installed configuration. The accompanying examples are incomplete seeds, not an overlay to copy blindly. Reconcile them with the current repository before applying them. Work in an isolated branch or worktree and preserve unrelated user changes.

Audited repository: `https://github.com/Victor-Tau/tauapi`.
Audited revision: `ebc4cebd9c7edee2743700310fd877984ed349eb`.
Audit date: `2026-11-06`.

The audit confirmed remote HEAD matched that revision. Re-check HEAD when starting implementation. No project builds, tests, deployments, or live-host probes were performed for this design. Do not promote historical acceptance records to current evidence.

## Non-negotiable design outcomes

1. One canonical home for every active policy and cross-component invariant.
2. Selective reading: bootstrap, route, domain, contract, source, validation.
3. English agent documents and plain Chinese human documents, with explicit upstream exceptions.
4. Source-linked documentation with a type, lifecycle status, responsible area, and verification scope.
5. Independent frontend and backend subtree builds inside the existing monorepo.
6. Documentation and executable checks evolve in the same change when their behavior changes.
7. Required checks distinguish passed, failed, skipped, blocked, and not_run.
8. Normal work proceeds autonomously inside existing authorization. Do not add routine human sign-offs.
9. Historical plans, proposed designs, current intent, current implementation, and observed deployment state remain distinguishable.
10. No claims of enforcement until the relevant checker is wired into an independently executed required gate.

## A. Establish the current baseline

Read root and applicable component instructions before changing files. Inventory tracked Markdown, agent entry points, schemas, generated artifacts, CI definitions, runbooks, and source-of-truth JSON files. Use Git-tracked paths and record the inspected revision.

Verify these observed facts against the new baseline:

- One repository contains `tauapi-fe`, `tauapi-be`, and `tauapi-ops`.
- Release builders export one subtree with `git archive <revision>:<component>`.
- The frontend is a static React/TypeScript/Rsbuild application.
- The backend is API-only and contains three Go modules: the host, `relaykit`, and `tokenkit`.
- Nginx serves explicit frontend routes/assets; other paths reach backend dispatch, including plugins.
- The current root has no `.github/workflows` directory; inherited backend workflows are nested.
- Old instruction files still refer to `web/`, `electron/`, or separate repositories.
- `PLAN.md` references an absent `GOAL.md` and superseded bootstrap phases.
- Existing billing rules and authentication/plugin contracts contain substantial detail worth preserving.

Create a migration ledger: old path, audience, provenance, current authority, destination, retained invariants, inbound links, migration action, and verification status. Do not bulk-delete old documents before resolving inbound links and preserving useful constraints.

## B. Implement the entry hierarchy

Create a root `CLAUDE.md` whose essential content is `@AGENTS.md`. Use the same thin adapter beside each component's `AGENTS.md`. Avoid a second copy of the policy. The root policy governs the repository; component rules add local constraints and cannot silently weaken global invariants.

Use same-directory imports to reduce path ambiguity, but do not assume they eliminate external-import trust checks: an ancestor policy imported while the session starts in a component may still lie outside its working directory. The canonical automation runner should resolve the Git root and launch Claude there. Separately verify direct component launches and document any trust or loading limitation without adding per-task confirmation. Agents normally work in the whole repository; isolated subtree archives are build contexts, not an independent replacement for the full maintenance workspace. Builds must not acquire a dependency on root governance files.

Inspect the installed Claude Code version and settings. Exercise actual loading from the root and all three component directories. Confirm expected policy content appears and obsolete upstream rules do not act as current navigation. Do not assume a user has the latest version or default instruction settings.

Root `AGENTS.md` should contain only stable global rules:

- Identify repository root and preserve existing work.
- Read `docs/ai/INDEX.md`, choose task routes, then read applicable local policy and contracts.
- Separate intended behavior, implementation evidence, and runtime observations.
- Preserve release-unit separation, API-only backend behavior, and upstream attribution.
- Use meaningful tests and report incomplete checks truthfully.
- Update affected documents with code; permit reasoned no-impact decisions.
- Keep agent documents English and human summaries Chinese.
- Recover task context after interruption or compaction.
- Continue authorized, reversible implementation work; escalate only a real unresolved decision or authority gap.

Target approximately 80–120 lines for the root and 60–120 for component policies. These are project maintenance targets, not runtime limits. Never shorten a document by deleting a necessary safety invariant.

Put domain explanations behind ordinary Markdown links. Use import syntax only for deliberately always-loaded policy. Path-scoped `.claude/rules` files should be brief reminders and links to canonical contracts, not duplicated full specifications.

## C. Create the documentation layout

| Location | Role |
| --- | --- |
| `docs/ai/INDEX.md` | Agent starting point and use of the task router |
| `docs/ai/REPOSITORY_MAP.md` | Stable architecture and release boundaries |
| `docs/ai/registry.yaml` | Canonical document/domain/path/check registry |
| `docs/ai/TASK_INDEX.md` | Generated selective navigation |
| `docs/ai/contracts/` | Cross-component intended behavior |
| `docs/ai/workflows/` | Feature, bugfix, upstream-sync, and documentation workflows |
| `docs/ai/decisions/` | Accepted, proposed, and superseded architecture decisions |
| `docs/ai/changes/active/` | Compact resumable records for ongoing work |
| `docs/ai/changes/archive/` | Completed conclusions and evidence references |
| `docs/ai/templates/` | Templates with purpose-specific sections |
| `docs/zh-CN/` | Human overview, operations, release notes, and troubleshooting |
| `<component>/docs/ai/INDEX.md` | Component domain navigation |
| `<component>/docs/ai/modules/` | Source-linked domain cards |
| `tauapi-ops/docs/ai/runbooks/` | Executable procedures and failure recovery |
| `scripts/docs/` | Registry, link, impact, and generated-index checkers |
| `.github/workflows/` | Monorepo CI entry points |

Do not create empty documents to fill this layout. Create a card when its content is useful. Do not put per-provider documentation files inside `plugins/tasks/*`; retain the existing central plugin-contract approach.

The existing instruction requiring explicit requests before creating `docs/` should be updated to the new allowed documentation locations, because this implementation explicitly establishes the documentation system. Preserve the useful restriction against scattered plugin READMEs.

## D. Specify authority and metadata

Assign each maintained document a stable ID and a type: policy, index, module, contract, workflow, runbook, decision, change, evidence, or human-guide.

Use lifecycle statuses consistently: draft, active, historical, superseded, deprecated. Represent generated content with a separate field, not as a competing lifecycle status. Required metadata depends on document type; tiny adapters need no frontmatter.

For substantive active technical documents record:

- `id`, `type`, `status`, `owner_area`.
- Existing `source_paths` and, where useful, stable source symbols.
- Related contract IDs and test/check IDs.
- A truthful verification basis: revision, timestamp, method, scope, and gaps.
- `supersedes` or `superseded_by` when relevant.

The registry is the canonical routing/ownership map. Do not maintain the same mapping by hand in frontmatter, a table, and a script. Choose fields held in the registry and generate their rendered indexes. If frontmatter repeats any field for portability, check equality.

Treat metadata as project schema. Claude does not automatically enforce arbitrary fields such as owner, status, or required_checks. Implement their meaning in the repository checker.

Answer questions with the appropriate source:

- Intended behavior: active contracts and accepted decisions, subject to current authorized requirements.
- Actual behavior: current implementation and reproducible tests.
- Deployed behavior: timestamped observations plus release metadata from the target environment.
- Past work: immutable evidence for its recorded revision and environment.
- Work in progress: the task record reconciled with the actual worktree and diff.

Do not settle contradictions by choosing the newest modification time. Record the discrepancy and establish intent. Fix an implementation bug without rewriting the contract to excuse it; update an obsolete description when evidence shows intent changed.

## E. Migrate high-value contracts first

### Routing and origin

Keep `tauapi-ops/ROUTE_CONTRACT.json` as the route-split data source. Explain priority, API-only fallback, same-origin HTTP, plugin reachability, reserved namespaces, asset behavior, and changed-route checks in `docs/ai/contracts/routing-and-origin.md`.

Avoid a second manually maintained exhaustive route list. Frontend source routing, runtime backend registrations, and route-contract data serve different roles. A route audit should compare them and record exceptions rather than claiming one regex scan proves all dynamic behavior.

### Authentication and authorization

Translate the operative technical content of `tauapi-be/docs/authentication.md` into an English canonical contract, with an obligation-by-obligation migration ledger. Include dashboard sessions, PAT policy, relay keys, refresh rotation/concurrency, cookie/Origin rules, server-side authorization, revocation, and cross-instance cache behavior. Link frontend HTTP/session/store implementations and backend services/models.

Retain the existing route-policy coverage test for newly added dashboard APIs. Produce a short Chinese guide for user-visible login/session behavior; it is not a duplicate technical spec.

### Billing and quota

Preserve every applicable invariant from `tauapi-be/.agents/rules/billing.md`, including passthrough and metadata validation, bounded multipliers, quota conversion helpers, saturation auditing, pre-consume/settle/refund paths, image payload counting, SSE completion versus client abort, and async task settlement races.

Do not replace these with a generic rule such as "avoid overflow." Migrate or explicitly reference one canonical English contract. Remove the old active duplicate only after recording where each obligation moved. Reconcile mixed-language expression documentation and retain provenance.

Treat the backend expression fixture as the canonical contract sample and the frontend fixture as a checked local snapshot. Implement deterministic synchronization and hash comparison, while keeping each subtree independently buildable. Updating a fixture alone is not proof that both implementations preserve semantics.

Keep import provenance separate from local contract evolution. `UPSTREAM.json` records what was imported; do not overwrite its upstream hash with a local fixture change. Record a local contract revision/hash separately and check both existing semantic consumers.

### Task plugins

Keep Markdown, JSON Schema, TypeScript definitions, host validation, and plugin tests coherent. Cover native routes versus host protocols, usage fact bounds, polling, completion/failure/refund behavior, and compatibility. Centralize the documentation rather than duplicating it per provider.

### Frontend release

Cover versioned immutable assets, uncacheable entry/version responses, missing-asset 404, old-tab behavior, release notification, atomic switching, and compatibility with running backends.

Use explicit API-contract versions, capabilities, or validated support lists. Do not compare Git hashes using semantic version ordering. Mark existing compatibility fields as declarations until an actual check rejects incompatible deployment.

### Backend release and schema

Cover master/slave migration responsibility, rolling mixed-version behavior, draining, pause/recovery, application rollback, and data recovery. Missing compatibility metadata must remain unknown; it must not default to safe.

Design release metadata with explicit schema-change status, migration identifiers, old/new application compatibility, evidence references, and rollback method. Determine a reliable producer before consuming these fields as gates. A release-record field added manually by the author is not sufficient evidence on its own.

Every rollback entry point must share the same compatibility validation, including `deploy-backend.sh --rollback`. Fixing only the wrapper or only adding a JSON field does not close the control gap.

## F. Create source-linked domain cards

Start with the following domains; expand only when actual maintenance needs justify it:

- Backend: authentication/authorization; relay/provider routing; billing/quota; task plugins; persistence/migrations; independent libraries.
- Frontend: shell/routing; authentication; data access; shared components/theme/i18n/accessibility; billing presentation.
- Operations: routing; frontend releases; backend releases; backup/restore; upstream synchronization.

Each card contains responsibility, exclusions, source entry points/symbols, a short request or data flow, consumed/provided contracts, invariant links, validation entry points, common failure locations, and documentation update triggers. Prefer source paths and symbols to fixed line numbers. Do not restate entire implementations or dependency lists that code already supplies.

## G. Implement routing and change-impact rules

Maintain one registry with component ownership, overlapping domain patterns, task intents, required reads, contract references, and named check profiles. Use the example only as a starting shape: it intentionally omits much of the full source coverage.

Compute impact as the union of:

1. Task intent, including meaning extracted from Chinese user requests.
2. Expected file paths from planning.
3. Actual additions, modifications, deletions, and renames in the final diff.
4. Cross-component dependency/contract edges.

Do not treat English keyword matching as a complete semantic classifier. Do not stop at the first matching domain. A plugin-only change can affect billing and routing. A generic model change can affect authentication, persistence, and caching.

Every changed first-party source path must have a primary component owner. Secondary domains may overlap. Unclassified paths trigger conservative routing and a missing-mapping finding, never a silent exemption. Exclusions for vendor/generated files must be explicit and narrow; generated output still has an owner and a source.

For each affected contract, require either an updated contract or a reasoned `reviewed_unchanged` disposition with evidence. Allow `docs_impact: none` for changes with no documented behavior impact. The checker validates completeness and consistency; it cannot prove the author's semantic judgment is correct.

Generate a compact task index and optional path-scoped reminders from the same registry. Preserve semantic triggers in the workflow because file globs alone cannot find every billing/authentication effect.

## H. Make validation executable

Create root CI workflows with correct `working-directory` values and explicit toolchain setup. Pin tools/actions according to the repository's maintenance policy. Nested `.github/workflows` files must not be described as active monorepo checks.

Use a root aggregate required check with an explicit final status. Job-level impact selection may avoid unnecessary suites, but a workflow excluded by path filters must not leave a required check permanently pending. A justified not-applicable result is distinct from a required skipped test.

Reuse existing project commands rather than inventing alternative suites:

| Profile | Working directory | Existing command or implementation anchor |
| --- | --- | --- |
| Backend modules | `tauapi-be` | `make test` covers host, relaykit, tokenkit |
| Backend build | `tauapi-be` | `make build` / existing API-only builder |
| Frontend typecheck | `tauapi-fe` | `bun run typecheck` |
| Frontend tests | `tauapi-fe` | `bun run test` |
| Frontend build | `tauapi-fe` | `bun run build` |
| Frontend lint | `tauapi-fe` | `bun run lint`, with a verified debt policy |
| Plugin checks | `tauapi-be` | `make lint-plugins`, `make format-plugins-check` |
| Isolated builds | Repository root | Adapt `verify-independent-builds.sh` to the candidate revision |
| Route analysis | Repository root | `generate-nginx.py`, explicit plugin input, plus behavioral route tests |

The existing isolated-build verifier uses `main`; make candidate-revision selection explicit before using it to certify a PR. A check of `main` is not evidence for a different candidate.

Add document checks for internal links/anchors, source paths, unique IDs, lifecycle/provenance, ownership, generated freshness, valid command working directories, and contract dispositions. Implement a specified glob dialect and test boundary cases, including direct-child files, renames, deleted paths, and overlapping domains.

Add meaningful negative checker tests: broken link, missing source, unmatched code, new frontend route omitted from routing, changed expression snapshot on one side, and required database credentials absent. These validate real gate behavior rather than mirror implementation.

Database profiles must provision real SQLite/MySQL/PostgreSQL where required by current project policy. Detect missing DSNs and relevant skipped tests before reporting success. Cover fresh schema, released-schema upgrade, repeated startup, preservation of existing data/constraints, and log databases when affected. Preserve minimum-supported-version checks for version-sensitive behavior.

Re-run lint to establish the current baseline. A historic count is not a reliable exemption. Baseline diagnostics by rule/file/stable location or fingerprint and tool version; reject new diagnostics, remove fixed ones, and require a separate justified policy change to expand exceptions. Do not turn off rules to obtain a green result.

Bind validation artifacts to the exact candidate revision and check-run identity, with command, cwd, tool versions, environment class, timestamps, exit status, meaningful skipped-test information, and log references. Store CI evidence outside the commit being checked to avoid self-referential commit hashes. Worktree checks must include a source/test/config digest or be rerun after commit.

Make required statuses enforceable in repository rules. Protect governance/checker changes with independent validation or a separate trusted review policy. This need not be a human approval on every normal task; it must prevent a change from weakening its own gate and then certifying itself.

## I. Add resumable workflows without bureaucratic overhead

Use one compact change record for ordinary work. Expand it for multi-session, cross-component, billing/authentication, database, release, or upstream changes. Track objective, acceptance criteria, base revision, scope, required documents, affected contracts, plan, known findings, validation, documentation dispositions, and next action.

Do not store hidden reasoning, chat transcripts, credentials, personal data, or unbounded logs. Record observable facts and decisions. Use CI artifacts for raw test logs and large screenshots; store durable summaries and redacted links in Git.

After completion, archive the record by date and keep a small generated active index. On resume, reread policy, task state, actual Git diff, and affected contracts. Recompute required reads if source or scope changed.

A committed task record may reference its last tested revision; it must not claim to contain its own final commit hash. The author marks a candidate `ready_for_ci`. The authoritative verified outcome is the external CI verdict for the exact candidate being merged, not an author-written status field. A later archival commit references the already validated implementation revision and receives its own documentation checks; it need not pretend the earlier implementation test ran on the archival commit. Re-run relevant checks whenever later edits affect their inputs.

Delegate with explicit scope, write ownership, required document paths, invariant IDs, candidate revision, and expected evidence. Do not assume a child agent inherits the parent's reads. The integrating agent reruns impact analysis and required checks on the combined diff.

Hooks may improve prompt timing: SessionStart points to recovery, PreToolUse catches known early violations, and Stop identifies missing completion fields with bounded retries. Do not use a read receipt as proof of comprehension. Keep read-only discovery available and ensure hooks cannot trap a blocked task in an endless loop. Final merge/release decisions rely on independent CI and execution permissions.

## J. Migrate history and protect upstream ownership

- Convert the current Chinese `map.md` to a concise human view; move stable AI architecture into the English map. Remove mandatory AI dependency on the Chinese version.
- Mark bootstrap `PLAN.md` and old status/evidence as historical with their dates and revision scopes. Preserve useful evidence and replace active navigation links.
- Split `DECISIONS.md` into current accepted decisions with explicit supersession, preserving the original as history.
- Keep `DEPLOYMENT_STATE.json` as a timestamped snapshot or explicitly generated report, never unconditional live truth.
- Preserve LICENSE, NOTICE, required upstream READMEs, third-party attribution, and UI locale assets. Document their provenance and exceptions to new-document language rules.
- Retain upstream raw instruction originals in vendor history or clearly named non-active references. Do not place accidentally auto-loaded `CLAUDE.md` copies throughout history directories.
- Update the upstream import/sync review process so imported AGENTS/CLAUDE files and `.agents` content cannot silently replace first-party active policy. Keep raw vendor imports faithful; resolve local integration deliberately instead of dropping upstream safety changes.

When migrating authoritative Chinese technical content, produce a full English technical version and verify completeness against the original obligations. A short English index pointing back to untranslated operative rules is only a transitional state, not completion of the requested language policy.

## K. Track executable gaps separately

The audit found these implementation gaps. Record each as an explicit follow-up with its own scope and regression evidence; do not mark it fixed by adding documentation:

1. Fresh-host bootstrap runbook starts slave before the script's initialization precondition.
2. Frontend release compatibility is logged rather than enforced.
3. Backend rollback reads `schema_changed`, but deployment does not populate it.
4. Route conflict analysis is optional and regex-based, not complete dynamic coverage.
5. Required database tests can be skipped when DSNs are absent.
6. Monorepo root CI and branch protection are not evidenced by nested workflow files.

Documentation migration can explain these limits immediately. Changing business/release behavior should be a concrete, separately validated implementation step within the scope granted for the rollout. Never run production mutations merely to validate the documentation migration.

## L. Rollout and acceptance

Deliver four reviewable increments:

1. Current facts, provenance, language policy, root/component entry points, and historical redirects.
2. Six high-value contract areas, domain cards, and resumable task templates.
3. Registry/checker/generated navigation plus root CI, required profiles, and evidence handling.
4. Task-routing and recovery drills, upstream-refresh checks, and remaining gaps documented with exact status.

Separate documentation/governance acceptance from release-safety follow-ups. The documentation rollout must expose unknown compatibility and must not claim the current scripts reject it. Runtime rejection across all release/rollback entry points is a later executable-fix acceptance criterion unless explicitly included in the granted implementation scope.

Maintain the system through change-triggered impact checks, upstream-import policy reviews, and a periodic documentation audit. The periodic audit reports broken sources, obsolete exceptions, and unresolved discrepancies; it must not update review dates without reviewing evidence. Keep compact durable conclusions in Git and define retention for external logs/screenshots so important evidence links do not expire unnoticed.

Use `ACCEPTANCE.md` for objective completion criteria. Report completed, blocked, and deferred items separately in a plain Chinese handoff. Do not claim active production safeguards or complete database compatibility unless the corresponding executable checks ran successfully for the delivered revision.
