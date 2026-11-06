# TauAPI agent policy

> Example target: repository-root AGENTS.md. Install only after the referenced
> navigation, contracts, and checks exist. Replace this note during rollout.

## Scope

TauAPI is one Git repository with independently built frontend and backend
release units and a shared operations component. Paths in this policy are
relative to the repository root unless stated otherwise.

Locate the root with Git. Inspect the branch and existing worktree changes.
Preserve unrelated changes. Work inside the scope and authority of the task.

## Read before editing

1. Read `docs/ai/INDEX.md`.
2. Select task routes using task meaning and expected source paths.
3. Read applicable component `AGENTS.md` files and domain cards.
4. Read every affected contract and the relevant source/test entry points.
5. Re-route against the actual diff before completing the change.

Follow links selectively. Do not read the whole documentation tree by default.
If routing misses a source area, inspect the repository map and repair the map.
Do not interpret a missing match as permission to skip a relevant contract.

## Authority and evidence

Active contracts describe intended behavior. Code and tests establish current
implementation behavior. Timestamped environment observations establish runtime
state. Historical acceptance reports apply only to their recorded revisions.

When these disagree, record the discrepancy and establish intended behavior.
Do not silently change an invariant to legitimize an implementation bug.
An accepted decision must identify any decision it supersedes.

## Architectural invariants

- Each release unit must build from its own exported subtree.
- The backend remains API-only. Preserve plugin dispatch and JSON fallback.
- Routing, authentication, billing, plugin, and release contracts are shared
  obligations even when the diff touches only one component.
- Preserve upstream licensing, attribution, provenance, and protected content.
- Keep secrets and production data out of documents and committed evidence.

## Validation and completion

Identify required checks before implementation. Reuse existing meaningful
regression suites. Add or extend tests when behavior or a defect requires them.
Do not add tests that only duplicate implementation or prove a function runs.

Record each check as passed, failed, skipped, blocked, or not_run. A required
skipped or blocked check is not a pass. Evidence must identify the tested source.
Do not weaken tests, baselines, contracts, or checkers just to pass a gate.

For each affected contract, update it or record why it remains correct.
Use `docs_impact: none` only with a concrete no-impact explanation.
Keep implementation, contract, and relevant human-facing changes together.

## Language and documentation ownership

Write policies, technical guides, contracts, workflows, decisions, task records,
check output, and code comments in English. Write human guides, release notes,
and user handoffs in plain Simplified Chinese.

Do not translate identifiers, commands, required upstream originals, license
texts, or existing UI locale assets. Preserve their provenance. Active agent
instructions must not depend on an untranslated upstream technical narrative.

## Long-running work and delegation

Keep a compact task record for work requiring a plan or session recovery.
Record facts, decisions, remaining checks, and the next action, not hidden
reasoning, chat transcripts, credentials, or unbounded logs.

On resume, reread this policy, the task state, actual diff, and relevant contracts.
Delegate with scope, required documents, invariant IDs, and expected evidence.
The integrating agent validates the combined result.

## Autonomous operation

Continue authorized, reversible work and fix routine failures without repeatedly
asking for confirmation. Escalate an unresolved business decision, missing
authority, missing necessary access, or an irreversible effect outside scope.
Documentation maintenance does not itself authorize production mutation.

Finish with a Chinese explanation of the outcome, validation, and remaining gaps.
