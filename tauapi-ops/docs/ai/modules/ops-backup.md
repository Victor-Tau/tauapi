# Backup and restore

## Responsibility and boundaries

This domain owns the backup and restore maintenance surface in `tauapi-ops`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-ops/scripts/backup.sh`
- `tauapi-ops/scripts/restore-check.sh`

Scheduled/authorized backup -> DB dump plus Git/meta -> isolated restore -> table/root/app-read assertions -> dated evidence.

## Consumed and provided contracts

- [backend-release-and-schema](../../../../docs/ai/contracts/backend-release-and-schema.md)

## Validation and failure localization

Selected checks: shell-syntax. See registry for literal runners and prerequisites.
Inspect backup exit status, permissions, isolated target and off-site availability. Never overwrite production or remove named volumes for a drill.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
