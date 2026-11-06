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
workflow-path classification and generated index whitespace when no active changes remain. Local checks and independent release scripts remain available.
Branch: task/remove-github-actions. Preserve the unrelated untracked root guide.

## Required reads
Root policy/index; docs-maintenance and tooling workflows; backend policy/index and engineering;
backend release/schema contract; repository map; known gaps; bootstrap record and change template.

## Work state
Completed. All six workflow source files removed locally and from GitHub main.
Repository Actions disabled; five runs deleted; GitHub reports zero workflows, runs and artifacts.
No Actions secrets, variables, artifacts, rulesets or main branch protection were configured.

## Checks
Local docs integrity, 33 checker tests, fixture equality, verify-change, final impact and diff whitespace checks passed.
GitHub source deletion: passed at 9e2bad24188883fcd90dbdedea57cbdbea4160d3.
No production deployment or data mutation.
Remote evidence: /tmp/tauapi-actions-removal-remote.json and /tmp/tauapi-actions-removal-final.json
(API responses, no credentials). Final API tree and settings readback confirmed the published deletion.

## Document dispositions
Governance documents and Chinese handoff updated. Bootstrap change record is now historical;
its CI activation next action is superseded. No application contract behavior changes.
Backend release/schema reviewed unchanged: workflow removal leaves source regression tests,
image contents and independent build/release scripts unchanged (BER-1 through BER-4).

## Next action
None for this task. Preserve local verification and keep GitHub Actions disabled.

## Outcome
Published workflow removal to GitHub main and independently read back repository source and settings.
Actions permissions enabled=false; workflow/run/artifact/secret/variable counts are zero.
No rulesets or main branch protection were configured. No unrelated settings or credentials changed.
