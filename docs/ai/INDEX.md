# Agent documentation entry

Read root policy, then use [the generated task index](TASK_INDEX.md).
Run `make docs-setup` once, then `make docs-check docs-test` from the Git root.
Route meaning and paths with `docs/tools/docsctl.py route --intent <text> --path <path>`.
Use `make docs-impact-worktree DOCS_BASE=<revision>` before finishing.

Authority: contracts declare intent; source/tests describe implementation; dated
observations describe deployments. Registry metadata records review scope, not runtime proof.
[Repository map](REPOSITORY_MAP.md) explains boundaries. [Known gaps](KNOWN_GAPS.md)
records unresolved safeguards. [Maintenance](workflows/docs-maintenance.md) defines daily work.
[Tooling](workflows/tooling.md) specifies matcher, CLI and evidence semantics.
Do not load the whole tree or bootstrap package for ordinary tasks.
