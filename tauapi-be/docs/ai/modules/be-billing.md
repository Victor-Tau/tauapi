# Billing and quota

## Responsibility and boundaries

This domain owns the billing and quota maintenance surface in `tauapi-be`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-be/relay/request_billing.go`
- `tauapi-be/common/quota_math.go`
- `tauapi-be/service/billing_session.go`
- `tauapi-be/service/task_billing.go`
- `tauapi-be/pkg/billingexpr`

Validated quantity -> PrepareRequestBilling -> estimated snapshot and BillingSession -> wallet/token reservation -> upstream usage -> checked conversion -> delta settlement/refund -> saturation audit.

## Consumed and provided contracts

- [billing-and-quota](../../../../docs/ai/contracts/billing-and-quota.md)

## Validation and failure localization

Selected checks: backend-tests, fixture-equality, billing-go, billing-fe. See registry for literal runners and prerequisites.
Inspect overflow and bypass at multipart/metadata inputs, group retries, image count adjustment and task completion races. Never patch a negative charge by hiding it in presentation.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
