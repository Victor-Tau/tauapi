# Task plugins

## Responsibility and boundaries

This domain owns the task plugins maintenance surface in `tauapi-be`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-be/pkg/jsplugin`
- `tauapi-be/plugins/tasks`
- `tauapi-be/service/task_polling.go`

Manifest/schema validation -> native route or host protocol -> plugin upstream request -> frozen usage/expression -> immediate result or persisted polling -> guarded complete/fail transition -> settlement/refund.

## Consumed and provided contracts

- [task-plugins](../../../../docs/ai/contracts/task-plugins.md)
- [billing-and-quota](../../../../docs/ai/contracts/billing-and-quota.md)
- [routing-and-origin](../../../../docs/ai/contracts/routing-and-origin.md)

## Validation and failure localization

Selected checks: plugins-lint, plugins-format, backend-tests, route-analysis. See registry for literal runners and prerequisites.
Inspect route precedence, profile selection, usage bounds and completion CAS. Duplicate polling and late failures must retain state and accounting semantics; metadata wording requires separate review.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
