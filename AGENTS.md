# TauAPI maintenance policy

Locate the Git root, preserve unrelated work, and use a task branch.
This repository contains two independent release units, `tauapi-fe` and `tauapi-be`,
plus operations in `tauapi-ops`.

## Read and change

Use [the task index](docs/ai/INDEX.md) to select component policies and contracts by
intent and paths. Read [shared engineering rules](docs/ai/engineering.md) for code work.
Follow [documentation maintenance](docs/ai/workflows/docs-maintenance.md) for every
implementation or debugging task. Read only affected documents.

Root rules apply to every component; component `AGENTS.md` adds local requirements.
Keep shared rules at root, component rules in their component, and cross-component
behavior in root contracts. `AGENTS.md` is the agent entry; use no `CLAUDE.md` adapters.
Contracts define intended behavior, source/tests establish implementation, and dated
observations record deployments. Fix contradictions at their source.

## Boundaries

Builders export `git archive <rev>:<component>`. Each release unit builds from its
own subtree. Root tooling and sibling sources are not build dependencies.
The backend is API-only. RelayKit and TokenKit remain independent Go modules.
Preserve New API / QuantumNous identity, module paths, copyrights, licenses,
notices, upstream READMEs and attribution. Keep protected originals in their language.
Read authentication, billing, persistence and release contracts before affected work.

## Verify and document

Maintain one compact task record using the [change template](docs/ai/templates/change.md).
Update affected documents and run meaningful candidate checks. Run
`make docs-check docs-test` and final worktree impact analysis before handoff.
Record each affected contract as updated, reviewed_unchanged or not_applicable,
with a reason and evidence. Explain any no-impact decision.
Report passed, failed, skipped, blocked and not_run separately. Required skips fail completion.
Run checks locally. Restore GitHub Actions only with explicit user authorization.

Root Markdown files are `AGENTS.md` and `README.md`. Project Chinese documentation is
limited to `README.md`, `docs/map.md` and `docs/CHANGELOG.md`; upstream originals retain
their filenames and language. Technical policies, contracts, task records, comments,
commits and logs use English. Write direct instructions and concrete facts.
Update the registry for document moves and generate the index; do not edit it by hand.
Keep completed task summaries in CHANGELOG and retrieve detailed history through Git.

## Resume and scope

On resume, read this policy, the index, the active task record and actual Git diff.
Reload contracts when scope changes. Record facts and evidence without credentials.
If delegation is authorized, specify write ownership, reads, invariant IDs, candidate
and expected evidence; review the integrated diff.
Continue authorized reversible work. Escalate unresolved decisions or missing access.
Production deployments, database mutations and external publication require their own scope.
