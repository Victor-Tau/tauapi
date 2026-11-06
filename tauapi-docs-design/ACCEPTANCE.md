# Documentation-system acceptance

These are proposed rollout criteria, not results of the design audit.

## Entry and selective reading

- [ ] A new Claude Code session from the repository root loads the global policy.
- [ ] The automation launcher resolves Git root from each component; supported direct launches also yield the correct global/local policy, with trust/loading limitations explicitly tested.
- [ ] The installed Claude Code version/settings and observed loading behavior are recorded.
- [ ] Required content remains discoverable after session recovery or compaction.
- [ ] Thin adapters do not duplicate policy text or import the whole document tree.
- [ ] Normal task routing excludes unrelated history and domain guides.
- [ ] Delegated tasks receive explicit scope, required reads, and evidence requirements.

## Authority, language, and migration

- [ ] Every active document has one purpose, owner area, and lifecycle status.
- [ ] Every migrated invariant from old billing/auth/database rules has a destination.
- [ ] Current navigation no longer depends on nonexistent `web/` or an absent `GOAL.md`.
- [ ] Historical bootstrap plans and deployment snapshots are labeled by date/revision.
- [ ] Active AI technical instructions are English; human guides and handoffs are Chinese.
- [ ] Upstream originals, licensing, provenance, and UI locale assets are preserved appropriately.
- [ ] Human summaries are related to English sources without being duplicate technical specifications.
- [ ] New upstream imports cannot silently replace active local instruction policy.

## Registry and document checks

- [ ] Every changed first-party source has a component owner.
- [ ] Overlapping domain matches are combined rather than first-match-wins.
- [ ] Intent-based triggers include cross-cutting effects outside narrow path patterns.
- [ ] Document IDs, source paths, internal links, anchors, and check working directories validate.
- [ ] Generated task indexes and any generated reminders match the registry.
- [ ] Unknown paths, deleted sources, and renames have specified behavior.
- [ ] No active authority link silently resolves to a superseded or historical policy.
- [ ] Affected documents are updated or have concrete unchanged/no-impact dispositions.

## Executable gates

- [ ] Root GitHub Actions workflows execute on the actual candidate revision.
- [ ] Required checks report a final outcome even when individual jobs are conditionally unnecessary.
- [ ] Changes to workflows/checkers cannot self-certify weakened enforcement unnoticed.
- [ ] Backend validation covers all three Go modules when the full backend profile is required.
- [ ] Database profiles run real supported engines and reject missing required DSNs/skipped cases.
- [ ] Lint debt is freshly established and fingerprinted; new findings are rejected.
- [ ] Independent builds export the candidate subtree and have no sibling dependency.
- [ ] Billing fixture equality preserves upstream provenance and checks both semantic consumers.
- [ ] Route checks cover behavior beyond the generator's literal plugin-path scan.
- [ ] Evidence identifies candidate revision/digest, command, cwd, environment, status, and logs.
- [ ] A failed checker, missing artifact, or unrun test cannot produce a pass result.

## Negative verification cases

| Injected defect | Required observation |
| --- | --- |
| Broken active-doc link | Documentation check fails with the source and target |
| Unowned new source file | Impact check requests a valid mapping |
| A new SPA route missing from split routing | Route behavior/coverage check fails |
| Only one billing-expression fixture changes | Contract equality check fails |
| Required MySQL/PostgreSQL DSN absent | Database profile is blocked or fails, never passes |
| Test logs correspond to a different revision | Evidence validation rejects them |
| A contract is silently weakened to match a bug | Contract/checker review identifies the policy change |
| Unknown schema compatibility in a documentation review | The gap stays explicit; no active document or evidence claims that current scripts enforce safety |

## Separate release-safety follow-up

These criteria belong to executable release fixes, not to documentation migration
alone. Include them in the completion verdict only when that implementation work
is within scope:

- [ ] Fresh-host bootstrap sequencing passes an isolated end-to-end exercise.
- [ ] Frontend deployment rejects incompatible backend capabilities before switching.
- [ ] Reliable schema metadata is produced and unknown compatibility is preserved.
- [ ] Every rollback entry point uses the same guard and rejects unknown/unsafe compatibility.
- [ ] Negative runtime tests verify rejection and leave the environment in the documented state.

## Representative maintenance drills

1. Add a frontend page: find source route, feature, route contract, direct-load validation, and relevant human description.
2. Diagnose a refresh loop: trace frontend session handling to backend rotation, authorization, and configuration; avoid an unrelated token-duration workaround.
3. Fix an image billing count: load all quantity/streaming invariants and extend existing behavioral tests.
4. Add a persisted field: select the database matrix and migration/repeated-start compatibility checks.
5. Import an upstream change: protect local entry points, inspect affected contracts, compare fixtures, and verify the candidate subtree builds.

## Handoff

- [ ] Completed, blocked, and deferred work is distinguished.
- [ ] Current production behavior is claimed only from actual authorized observation.
- [ ] Known executable gaps remain open until their actual fixes pass validation.
- [ ] The user receives a clear Chinese explanation of outcome, impact, and remaining work.
- [ ] The project remains maintainable without relying on one agent's private memory.
- [ ] Author-written task status is not treated as a CI verdict; archival commits reference the implementation revision without self-referential hashes.
