# Relay and providers

## Responsibility and boundaries

This domain owns the relay and providers maintenance surface in `tauapi-be`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-be/router/relay-router.go`
- `tauapi-be/middleware/distributor.go`
- `tauapi-be/controller/relay.go`
- `tauapi-be/relay`

Relay route -> API key -> distributor/channel selection -> controller.Relay -> provider DTO conversion -> HTTP/SSE/WS -> usage normalization and settlement.

## Consumed and provided contracts

- [routing-and-origin](../../../../docs/ai/contracts/routing-and-origin.md)
- [billing-and-quota](../../../../docs/ai/contracts/billing-and-quota.md)

## Validation and failure localization

Selected checks: backend-tests, route-analysis. See registry for literal runners and prerequisites.
Localize protocol loss before changing billing. Check optional scalar pointers preserve explicit zero, stream flushing and plugin fallback JSON 404. Add StreamOptions support only after provider capability review.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
