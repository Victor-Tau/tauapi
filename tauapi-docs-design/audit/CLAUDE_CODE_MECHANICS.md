# Claude Code mechanics for the tauapi documentation design

Reviewed: 2026-11-06 (Asia/Singapore).
Status: design reference; no runtime configuration is installed by this note.
The maintainer's installed Claude Code version and effective settings are unknown.

## 1. Loading mechanisms verified in the official documentation

Startup includes instructions from the working directory and its ancestors.
Nested instructions load as Claude accesses their directories. Keep each entry
file short; the official recommendation of about 200 lines is guidance, not a
project acceptance threshold. [Extension overview][overview]

The following details come from the [memory reference][memory]:

- `@path` imports load immediately with their containing instruction file;
  relative paths resolve from that file. Recursive imports allow four hops.
- Direct `AGENTS.md` support starts at v2.1.277. Before v2.1.281, some environments
  lack it. Default loading prefers `CLAUDE.md`, `.claude/CLAUDE.md`, or
  `CLAUDE.local.md` in the working directory or its ancestors.
- A same-directory `CLAUDE.md` containing `@AGENTS.md` remains supported without
  duplicate loading. A prose request to read another file is not an import.
- `.claude/rules/` supports conditional rules through `paths` frontmatter.
  Other frontmatter fields are ignored; rules without `paths` are not conditional.
  Project path patterns are relative to the directory containing `.claude`.
- Root instructions reload after compaction. Nested instructions and path rules
  reload on demand.
- Instruction files provide behavioral context, not enforced configuration.

## 2. Recommended entry points and scopes

Use `AGENTS.md` as the canonical shared policy and a thin `CLAUDE.md` adapter at
the root and at component boundaries that need their own instructions.
Maintain one canonical copy of each rule. Local rules should add precise scope,
not silently redefine a global invariant.

Import only the small mandatory policy. Use ordinary links in the task router
for module guides, contracts, workflows, and evidence that should be read when
relevant. Imported documents do not provide deferred loading.

Treat the proposed documentation manifest, status fields, source mappings, and
review receipts as tauapi conventions. They require a repository validator;
Claude Code does not execute a custom documentation schema automatically.

Avoid relying on launch-directory accidents. Check root and component launches,
and give standalone component checkouts their own usable policy entry point.
Do not assume a sibling checkout's instructions are automatically available.

## 3. Skills, delegation, and recovery

Skills expose descriptions before use and load their bodies when invoked.
`disable-model-invocation: true` prevents autonomous invocation, so it is unsuitable
as a blanket setting for an automated maintenance workflow. [Skills reference][skills]

Ordinary subagents start with separate context, not the parent's conversation
or previously read files. Current built-in Explore and Plan agents omit project
instructions at startup; custom agents can preload named skills. [Subagents][agents]

For tauapi, every delegation should carry the task scope, required document
paths, applicable invariants, exact base revision, and expected evidence format.
Require the receiver to resolve those paths before proposing code changes.

Persist task state outside the chat: current objective, affected modules,
validated assumptions, completed checks, unresolved failures, and next action.
After resuming or compacting, reload that state and the relevant document set.
Treat personal auto memory as a hint; verified repository records own decisions.

## 4. Hooks and enforcement boundaries

`SessionStart` can restore task context, including after compaction.
`PreToolUse` can deny a tool call; use its documented
`hookSpecificOutput.permissionDecision` format. `Stop` can request more work and
provides `stop_hook_active` to help avoid endless continuation. [Hooks][hooks]

Ordinary project hooks can be disabled. Asynchronous hooks cannot block an action
that has already happened. Conventional failure code 1 and timeouts generally
do not block calls; policy hooks must use supported blocking behavior and be
tested on the installed version. Hooks run with the user's account permissions.

For tauapi, hooks should give immediate, bounded feedback. They must not become
the only merge or release gate. Logging a loaded document proves neither
comprehension nor compliance. A check maintained by the same unrestricted agent
does not by itself establish an independent security boundary.

## 5. Repository-level CI placement

GitHub Actions discovers workflow definitions under the repository's root
`.github/workflows/`. A workflow copied inside a component directory does not
become active for the enclosing repository. [GitHub workflow syntax][github]

For a single repository, put dispatching workflows at its root and run each job
in the relevant component directory. For independent repositories, each needs
its own root workflows. Required checks skipped by path filters can remain
pending; design an aggregate gate with an explicit result for every change.

Recommended independent gates cover documentation links and schema, changed
source ownership, contract impact, relevant tests, and release prerequisites.
Verify the actual branch policy and check results; checked-in YAML is not proof
that enforcement is active. Bind validation evidence to the tested revision.

## 6. Capability smoke test before adopting the design

1. Record `claude --version`, launch directory, and effective instruction settings.
2. Confirm the root adapter and a component adapter appear in loaded instructions.
3. Access matching and unrelated files to check conditional rule scope.
4. Confirm a linked module guide stays deferred until the task calls for it.
5. Exercise resume, compaction, and a delegated task using harmless sample work.
6. Verify hook success, rejection, failure, and timeout behavior in an isolated checkout.
7. Submit a harmless CI exercise and inspect the checks and merge requirements.

[memory]: https://code.claude.com/docs/en/memory
[overview]: https://code.claude.com/docs/en/features-overview
[skills]: https://code.claude.com/docs/en/skills
[agents]: https://code.claude.com/docs/en/sub-agents
[hooks]: https://code.claude.com/docs/en/hooks
[github]: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
