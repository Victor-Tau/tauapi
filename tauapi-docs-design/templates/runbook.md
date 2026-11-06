---
id: "REPLACE_RUNBOOK_ID"
type: runbook
status: draft
owner_area: operations
source_paths: []
verification:
  revision: null
  at: null
  environment: null
  scope: not_verified
  gaps: []
---

# Operation title

## Purpose and applicability

State the operation, target environment, required authority, affected resources,
and expected result. Distinguish initial setup from an already initialized host.

## Preconditions

List observable preconditions, including current release/state, lock ownership,
tool versions, backups when applicable, and compatibility. Never embed secrets.

## Procedure

| Step | Working directory and command | Expected result | Failure state and next action |
| --- | --- | --- | --- |
| 1 | Verified existing command | Concrete check | Preserve state and diagnose; no bypass |

Reuse maintained scripts. Document their parameters and exit codes. Do not
duplicate script internals as a second manually maintained procedure.

## Verification

Explain what establishes success and what the checks do not cover. Record
static review, isolated integration exercise, original-host execution, and
fresh-host end-to-end exercise as distinct verification scopes.

## Pause, retry, and recovery

Define safe resumable states and how to detect them. Include locks and partially
completed operations. For releases, distinguish application rollback from data
restoration and identify compatibility requirements for each entry point.

## Evidence

Record environment, source revision, artifact identifiers, commands, timestamps,
outcomes, and sanitized evidence references. Historical evidence is immutable;
new attempts create new records.
