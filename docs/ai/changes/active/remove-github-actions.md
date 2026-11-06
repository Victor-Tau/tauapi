# Remove GitHub Actions

## Objective
Remove all project GitHub Actions workflows and related GitHub configuration at user request.

## Acceptance criteria
No root or nested workflow files remain. GitHub Actions is disabled; runs and artifacts are absent.
Check Actions secrets/variables, rulesets and main protection without changing unrelated settings.
Publish source deletions to the GitHub default branch and verify them remotely.

## Base revision
cf202ac73ff12b462f2da2f7c4a9dcad7517ad41

## Scope
Six root/backend workflow files, current governance documentation, local hook messages and
workflow-path classification. Local checks and independent release scripts remain available.
Branch: task/remove-github-actions. Preserve the unrelated untracked root guide.

## Required reads
Root policy/index; docs-maintenance and tooling workflows; backend policy/index and engineering;
backend release/schema contract; repository map; known gaps; bootstrap record and change template.

## Work state
Local removal implemented. Remote workflow disabled and repository Actions disabled; five runs deleted.
No Actions secrets, variables, artifacts, rulesets or main branch protection were configured.

## Checks
Local docs integrity, 33 checker tests, fixture equality, verify-change, final impact and diff whitespace checks passed.
GitHub source deletion: not_run. No production deployment or data mutation.
Remote evidence: /tmp/tauapi-actions-removal-remote.json (API responses, no credentials).

## Document dispositions
Governance documents and Chinese handoff updated. Bootstrap change record is now historical;
its CI activation next action is superseded. No application contract behavior changes.
Backend release/schema reviewed unchanged: workflow removal leaves source regression tests,
image contents and independent build/release scripts unchanged (BER-1 through BER-4).

## Next action
Run documentation and checker tests, recompute final impact and publish/verify GitHub main.

## Outcome
Pending final validation and publication. No unrelated GitHub settings or credentials changed.
