# Tooling

Run make docs-setup from root to install pinned isolated Python tooling. Aliases use .docs-venv/bin/python.
Registry is JSON-compatible YAML (JSON syntax only), parsed with duplicate-key rejection and JSON Schema.
Normative unknown fields fail. It owns IDs, lifecycle, ownership, sources, domains, intents and check IDs.
Globs use POSIX paths: * excludes slash, ** spans directories, **/ includes zero directories, ? one non-slash.
Route computes overlapping union and contract consumers. Unowned paths fail; fallback-only source paths
require classification. Intents are explicit IDs plus Chinese/English trigger hints, not semantic proof.
Markdown checks ignore fenced examples, support inline/reference links and GitHub-style heading slugs;
external HTTP reachability is not an internal integrity check. Language heuristics flag obvious CJK in
English prose but quoted identifiers/UI strings need narrow reviewed exceptions.
Docs-check is read-only. Generate --write owns only TASK_INDEX.md; unchanged input is byte deterministic.
Revision diff resolves both endpoints; worktree includes untracked files with NUL-safe Git enumeration.
Missing baseline/prerequisite exits3, validation1, invocation2, internal4; every nonzero is unsuccessful.
Runner dispatch uses literal argv and no shell/eval. Run evidence records command/cwd/tools/time/exit,
commit or input digest, CI identity, environment, skips and logs. Required DB skips block, never pass.
Database profiles need real DSNs and released-schema evidence; never assume unit tests prove upgrades.
Bootstrap inputs are immutable provenance. Unchanged upstream references are explicitly inventoried.
Run audit on demand; do not install cron/daemons or refresh review dates without actual review.
Retain external logs/screenshots at least 90 days and keep durable summaries in Git.
GitHub Actions workflows are intentionally removed; run selected profiles locally.
Workflow configuration paths are documentation/tooling changes, including deleted nested workflows;
application source paths still require explicit domain classification.
Local checks do not enable remote branch protection.


Setup requires Python with venv/ensurepip, or an available uv (the Make target detects it).
Tool dependencies are pinned separately from application dependencies. Renames are deliberately
represented as deletion plus addition so both old and new obligations survive routing.
Root and component `AGENTS.md` files are the shared instruction entries for Codex and Claude Code.
Claude Code v2.1.277 or later loads them natively by default when no `CLAUDE.md`,
`.claude/CLAUDE.md` or `CLAUDE.local.md` is present in the working directory or its ancestors.
Older clients must be upgraded; do not regenerate adapter files. Bootstrap examples are immutable
references, not active instructions. Existing `.claude/rules/` and hooks retain their own roles.
The optional launcher is `bash docs/tools/claude-root.sh`; it resolves Git root from
any component before starting Claude. Direct component starts use ancestor and local `AGENTS.md`
without adapter imports. Do not rewrite user/global trust or instruction-file settings.
Official integration references: [memory](https://code.claude.com/docs/en/memory) and
[hooks](https://code.claude.com/docs/en/hooks). Runtime loading still needs installed-client observation.


Preserved bootstrap Markdown includes upstream/supplied trailing-space hard breaks. Do not edit
those bytes to satisfy whitespace cleanup; validate task-authored content separately from immutable input.
