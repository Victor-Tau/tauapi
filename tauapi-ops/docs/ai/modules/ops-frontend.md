# Frontend releases

## Responsibility and boundaries

This domain owns the frontend releases maintenance surface in `tauapi-ops`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-ops/scripts/build-frontend.sh`
- `tauapi-ops/scripts/deploy-frontend.sh`
- `tauapi-ops/scripts/rollback-frontend.sh`

Candidate subtree archive -> Bun typecheck/tests/build -> versioned artifact/manifest -> publish immutable assets -> atomic current switch -> old-tab/version/rollback checks.

## Consumed and provided contracts

- [frontend-release](../../../../docs/ai/contracts/frontend-release.md)

## Validation and failure localization

Selected checks: isolated-builds. See registry for literal runners and prerequisites.
Inspect manifest hashes, missing chunk 404, cache headers and retained releases. compatible_backend is logged only; do not infer compatibility enforcement.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
