# Data access

## Responsibility and boundaries

This domain owns the data access maintenance surface in `tauapi-fe`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-fe/src/lib/http-client.ts`
- `tauapi-fe/src/lib/query-client.ts`
- `tauapi-fe/src/lib/handle-server-error.ts`

Feature Query/Mutation -> shared API/http client -> dedup/cache/refresh -> requireServerSuccess -> query invalidation or final error handling.

## Consumed and provided contracts

- [authentication](../../../../docs/ai/contracts/authentication.md)
- [routing-and-origin](../../../../docs/ai/contracts/routing-and-origin.md)

## Validation and failure localization

Selected checks: frontend-typecheck, frontend-tests. See registry for literal runners and prerequisites.
Inspect query keys, stale cache and retry ownership. Final failures notify once; custom mutation errors own their notification. Preserve AuthOperationError safe mapping and never log Axios credentials.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
