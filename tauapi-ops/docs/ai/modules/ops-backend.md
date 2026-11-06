# Backend releases

## Responsibility and boundaries

This domain owns the backend releases maintenance surface in `tauapi-ops`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-ops/scripts/deploy-backend.sh`
- `tauapi-ops/scripts/rollback-backend.sh`
- `tauapi-ops/scripts/bootstrap-stack.sh`

Candidate API-only archive -> image -> remove instance from upstream -> drain -> master/slave replacement and setup/health checks -> readmission -> release record.

## Consumed and provided contracts

- [backend-release-and-schema](../../../../docs/ai/contracts/backend-release-and-schema.md)

## Validation and failure localization

Selected checks: isolated-builds. See registry for literal runners and prerequisites.
Inspect migration ownership, unknown schema state, mixed-version semantics, SSE/WS drain and paused recovery. App rollback cannot prove data rollback safety.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
