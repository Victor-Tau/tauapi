# TauAPI maintenance policy

Locate the Git root. This monorepo contains two independent release units,
`tauapi-fe` and `tauapi-be`, and operations in `tauapi-ops`.
Preserve unrelated staged, unstaged, and untracked work. Use a task branch.

## Start and route

`AGENTS.md` is the shared instruction entry for Codex and Claude Code, at the root
and within each component. Keep rules there instead of adding `CLAUDE.md` adapters.

Read [the active index](docs/ai/INDEX.md), classify task intent and expected paths,
then read applicable component policies, domain cards, and contracts.
Follow links selectively; bootstrap inputs and historical evidence are background.
Use [documentation maintenance](docs/ai/workflows/docs-maintenance.md) for every
implementation or debugging task, including final diff impact and dispositions.
Semantic triggers supplement path routing; combine every affected domain.

## Authority

Active contracts describe intended behavior. Current source and reproducible tests
establish implementation. Timestamped environment observations describe deployments.
Record contradictions and establish intent; never rewrite a contract to excuse a bug.
Deployment snapshots are observations, not unconditional live state.

## Boundaries

Frontend and backend builders export one component with `git archive <rev>:<component>`.
Neither build may depend on root governance or sibling sources. The backend remains
API-only; RelayKit and TokenKit remain independent Go modules.
Preserve New API / QuantumNous identity, module paths, copyright, licenses, notices,
upstream READMEs and attribution. Never translate protected upstream originals.
Authentication, billing, persistence and release constraints survive policy migration.
Read their canonical policies before working on affected behavior.

## Change and verify

Maintain one compact resumable change record; use the change template.
Update affected documents with behavior, including Chinese user-facing effects.
A `reviewed_unchanged` disposition needs a reason and source/evidence pointers.
A no-impact decision is allowed with a concrete explanation.
Run meaningful regression checks for the actual candidate. Report `passed`, `failed`,
`skipped`, `blocked`, and `not_run` distinctly. Required skips are unsuccessful.
Run `make docs-check docs-test` and final impact analysis before handoff.
Never treat a nested backend workflow as an active root merge gate.
Never claim remote enforcement from a checked-in workflow or author-written result.

## Language and provenance

Agent policies, technical contracts, task state, comments, commits and logs are English.
Human README, map, operations summaries and release notes use Simplified Chinese.
When a fact affects both audiences, update its human summary and technical authority.
Identifiers, paths, commands, quoted UI strings and immutable upstream originals are exempt.
The registry owns routing and document identity; generated navigation is never hand edited.

## Recovery and autonomy

On resume, reread this policy, the index, the active record and actual Git diff.
Reload contracts when scope changes. Record observable facts, not private reasoning,
chat transcripts, credentials or unbounded logs.
If delegation is authorized, specify write ownership, required reads, invariant IDs,
candidate and expected evidence; validate the integrated diff.
Continue authorized reversible work without routine confirmation. Escalate only a
concrete unresolved decision, missing access or authority gap.
Production deployment, database mutation and external publication need their own scope.
