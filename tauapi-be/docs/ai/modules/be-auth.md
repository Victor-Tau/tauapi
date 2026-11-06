# Authentication and authorization

## Responsibility and boundaries

This domain owns the authentication and authorization maintenance surface in `tauapi-be`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-be/middleware/auth.go`
- `tauapi-be/service/auth_session.go`
- `tauapi-be/service/auth_token.go`
- `tauapi-be/model/user_session.go`

Dashboard route -> credential classification -> JWT/session or PAT validation -> Casbin/scope/proof -> DB session/token state and bounded Redis cache -> response.

## Consumed and provided contracts

- [authentication](../../../../docs/ai/contracts/authentication.md)

## Validation and failure localization

Selected checks: backend-tests. See registry for literal runners and prerequisites.
Localize 401 at auth version, SID/refresh generation and cache topology; 409 at session mismatch or limits; 403 at declared scope/proof. Protect route-policy coverage, expiry, replay and revoke-others regressions.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
