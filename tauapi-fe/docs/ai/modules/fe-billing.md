# Billing presentation

## Responsibility and boundaries

This domain owns the billing presentation maintenance surface in `tauapi-fe`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-fe/src/features/pricing`
- `tauapi-fe/src/features/model-pricing`
- `tauapi-fe/src/features/usage-logs`
- `tauapi-fe/testdata/contracts/frontend_simulation.json`

Price option/log data -> expression parser/simulator -> visual/raw editor or billing display -> request-rule traces and normalized currency.

## Consumed and provided contracts

- [billing-and-quota](../../../../docs/ai/contracts/billing-and-quota.md)
- [task-plugins](../../../../docs/ai/contracts/task-plugins.md)

## Validation and failure localization

Selected checks: fixture-equality, billing-fe, frontend-typecheck. See registry for literal runners and prerequisites.
Compare frontend local fixture to backend canonical sample, then run both evaluators. Preserve token vs task USD scales, explicit zero prices, cache subdivisions and authoritative request_rules from logs.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
