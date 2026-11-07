# Documentation maintenance

## Daily work

1. Read root and affected component policies. Route intent and expected paths with
   `docs/tools/docsctl.py route --intent <text> --path <path>`. Read selected contracts.
2. Describe the trigger, expected behavior and acceptance cases in one task JSON
   under `docs/ai/changes/active/`, using the [change template](../templates/change.md).
3. Inspect source and tests, implement the change and update the owning documents.
   Summarize user effects in root README, `docs/map.md` or `docs/CHANGELOG.md`.
4. Run `make docs-impact-worktree DOCS_BASE=<base>` against the actual diff. Record
   updated, reviewed_unchanged or not_applicable for each affected contract, with a
   concrete reason and source/test evidence. Explain a no-impact decision.
5. Run selected checks and `make docs-check docs-test`. Record passed, failed, skipped,
   blocked and not_run separately. Required skips leave the task incomplete.
6. Mark the task completed after verification. On the next task, consolidate its
   durable outcome into CHANGELOG and remove the completed record; Git keeps details.

On resume, reread the active record and actual Git diff. Reload contracts when scope changes.
For bugs, reproduce the trigger and add a regression at the failing boundary. For features,
check existing implementations and consumer compatibility before adding code.
For upstream imports, follow operations engineering and review policy, VERSION, license,
fixture and schema changes before merging. Keep imported GitHub Actions workflows removed.

## Document ownership

Root `AGENTS.md` owns common maintenance rules. Component `AGENTS.md` adds local rules.
Root contracts own behavior shared by components. Component engineering documents own
local implementation guidance and source maps. Each rule has one authoritative location.
Use links for shared requirements. Keep technical text in English and user summaries in Chinese.
Preserve upstream README, license, attribution and reference files in their original language.

`registry.yaml` owns document IDs, paths, domains and check selection. Edit it when moving,
adding or deleting documents, then run `make docs-generate` to rebuild `INDEX.md`.
Completed plans and duplicate design packages belong in Git history.

## Tool commands

Run `make docs-setup` once; it installs pinned Python tools in `.docs-venv` using uv or venv.
The Make targets use that interpreter. `make docs-audit` checks integrity on demand.
`make docs-verify DOCS_BASE=<base> DOCS_HEAD=<candidate> DOCS_CHANGE=<record>` runs
selected profiles for a committed candidate and writes `.docs-reports`.
Use `docsctl.py verify-change --base <base> --worktree --record <record>` to check
worktree dispositions. Run required checks again after relevant candidate changes.

The registry uses JSON syntax within YAML, rejects duplicate keys and validates its schema.
Globs use POSIX paths: `*` excludes slash, `**` spans directories, `**/` includes zero
directories, and `?` matches one non-slash. Routing combines overlapping domains,
contract consumers and English/Chinese intent hints. Source paths need an explicit domain.
Impact combines baseline and candidate obligations and includes staged, unstaged,
untracked, deleted and renamed paths. Renames are deletion plus addition.

Checks cover registered Markdown, internal links and anchors, source paths, document
language, ownership, generated-index freshness, billing fixtures and literal frontend routes.
Fenced examples are ignored; external URL reachability is outside these checks.
`check` is read-only; only `generate --write` writes the generated index.
Exit codes: 0 passed, 1 validation failure, 2 invocation error, 3 missing prerequisite,
4 internal failure. All nonzero results are unsuccessful.

Runners use literal argv. Evidence records the candidate digest, commands, working directory,
tools, time, environment, exit status and logs. Database profiles require real DSNs and
released-schema upgrade evidence. Keep credentials out of records and logs.
Run checks locally; repository files do not configure remote branch protection.

## Agent integration

Root and component `AGENTS.md` files are the shared instruction entries. The optional
`bash docs/tools/claude-root.sh` launcher starts Claude from the Git root. Hooks in
`docs/tools/hooks/` add session context and check completion; they preserve user settings.
