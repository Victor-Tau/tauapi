# Upstream synchronization

## Responsibility and boundaries

This domain owns the upstream synchronization maintenance surface in `tauapi-ops`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-ops/scripts/import-upstream.py`
- `tauapi-ops/scripts/sync-upstream.sh`
- `tauapi-ops/UPSTREAM_LOCK.json`

Pinned SHA -> faithful vendor branches -> task upgrade branch subtree merges -> policy/fixture/VERSION/license review -> candidate tests -> deliberate merge.

## Consumed and provided contracts

- [routing-and-origin](../../../../docs/ai/contracts/routing-and-origin.md)
- [billing-and-quota](../../../../docs/ai/contracts/billing-and-quota.md)
- [task-plugins](../../../../docs/ai/contracts/task-plugins.md)

## Validation and failure localization

Selected checks: docs-integrity, fixture-equality, isolated-builds. See registry for literal runners and prerequisites.
Inspect AGENTS/CLAUDE/.agents/import mapping even without merge conflicts. Compare local fixture evolution separately from UPSTREAM import hashes; sync must not deploy.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
