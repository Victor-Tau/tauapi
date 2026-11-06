# Independent libraries

## Responsibility and boundaries

This domain owns the independent libraries maintenance surface in `tauapi-be`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-be/relaykit/go.mod`
- `tauapi-be/tokenkit/go.mod`
- `tauapi-be/relaykit/relayconvert`
- `tauapi-be/tokenkit`

Host prepares model/DTO/media metadata -> RelayKit conversion or TokenKit count -> host transports and accounts usage. Neither library owns sessions, network policy or billing.

## Consumed and provided contracts

- [billing-and-quota](../../../../docs/ai/contracts/billing-and-quota.md)

## Validation and failure localization

Selected checks: backend-tests, libraries-build. See registry for literal runners and prerequisites.
RelayKit selects request/response/stream conversion by concrete DTO; diagnostics report loss and steps. TokenKit counts supplied text/image dimensions without downloading or parsing host requests. Check each GOWORK=off module build.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
