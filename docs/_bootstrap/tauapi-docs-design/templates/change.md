---
id: "REPLACE_CHANGE_ID"
type: change
status: draft
work_status: planned
base_revision: null
owner_area: "REPLACE_AREA"
domains: []
contracts: []
docs_impact: pending
---

# Change objective

## Outcome and acceptance

State the requested outcome and observable completion criteria. Define relevant
non-goals only when they prevent real scope ambiguity.

## Scope and context

- Branch/worktree and baseline revision:
- Existing unrelated changes:
- Expected source paths and contract IDs:
- Required documents, reviewed revisions, and important discrepancies:

## Work plan and recovery

Keep a short ordered list. Record completed facts, unresolved hypotheses, the
next action, and commands needed to resume. Do not store hidden reasoning or
chat transcripts. Reconcile this section with the actual Git diff on resume.

## Validation

| Check | Required | Subject revision/digest | Status | Evidence or blocker |
| --- | --- | --- | --- | --- |
| REPLACE_CHECK | yes | Pending | not_run | Pending |

Allowed statuses: passed, failed, skipped, blocked, not_run. Required skipped,
blocked, or not_run checks prevent verified completion.

## Documentation disposition

| Affected document or contract | Disposition | Reason and evidence |
| --- | --- | --- |
| REPLACE_ID | pending | Pending |

Use updated, reviewed_unchanged, or not_applicable with an explanation. A blanket
"docs updated" is insufficient. Record necessary Chinese-guide updates.

## Final integration

Record final diff routing, candidate revision, CI evidence, unresolved limitations,
and durable outcome. Archive only after completion; preserve blocked work as
blocked. Write the user-facing handoff separately in Simplified Chinese.

Use `ready_for_ci` before the external candidate check. This committed record can
reference the last tested revision, not its own eventual commit hash. The CI
verdict for the candidate being merged owns verified status. A later archival
commit links the verified implementation revision and runs its own doc checks.
