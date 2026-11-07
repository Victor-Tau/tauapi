# TauAPI maintenance policy

Locate the Git root and preserve unrelated work. Perform all operations on `main`.
Do not create any branches, including task, feature, release, vendor or upgrade branches.
Keep worktrees and checkouts on the existing `main` branch; do not use detached HEAD
or another branch to bypass this rule.
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

## Release requirements

Release notes must use Simplified Chinese and contain only changes or updates.
Do not include build/test results, installation or deployment instructions, checksums,
credits, publication details or other commentary in release notes.
Compile release executables and images only for `linux-amd64` (`linux/amd64` for Docker).
SHA256 verification and SHA256 operations are prohibited: do not calculate, generate,
verify or publish SHA256 checksums, files or checksum metadata. Do not upload SHA256
content as release assets or include it inside release packages or release notes.
Follow the [release procedure](tauapi-ops/docs/ai/engineering.md#release-channel)
for every future build and publication.

## Verify and document

Maintain one compact task record using the [change template](docs/ai/templates/change.md).
Update affected documents and run meaningful candidate checks. Run
`make docs-check` and final worktree impact analysis before handoff.
Only test new or modified modules individually, using explicit package, test-file or
test-case targets. Full test suites are prohibited, including repository/component-wide
runs, recursive `go test ./...`, unfiltered frontend tests and unittest discovery.
Do not test unchanged modules or expand testing automatically through build/release tools.
When the user removes an unfinished check from scope, delete its check entry instead of
retaining an interrupted, pending, skipped or waived entry. Never report it as passed.
Record each affected contract as updated, reviewed_unchanged or not_applicable,
with a reason and evidence. Explain any no-impact decision.
Report actual completed check results accurately. Keep only checks within the authorized scope.
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
