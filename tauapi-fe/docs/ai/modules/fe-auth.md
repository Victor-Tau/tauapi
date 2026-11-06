# Authentication

## Responsibility and boundaries

This domain owns the authentication maintenance surface in `tauapi-fe`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-fe/src/lib/auth-session.ts`
- `tauapi-fe/src/lib/auth-session-sync.ts`
- `tauapi-fe/src/lib/http-client.ts`
- `tauapi-fe/src/stores`

Cold-start hint -> auth-session discovery -> shared HTTP refresh -> in-memory access token -> auth store -> route guard; Web Locks and SID-only cross-tab events coordinate refresh.

## Consumed and provided contracts

- [authentication](../../../../docs/ai/contracts/authentication.md)

## Validation and failure localization

Selected checks: frontend-typecheck, frontend-tests. See registry for literal runners and prerequisites.
Refresh loops require tracing both frontend identity and backend Cookie/Origin/SID handling. Never persist tokens or replay proof actions; distinguish transient failure from server-confirmed anonymity.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
