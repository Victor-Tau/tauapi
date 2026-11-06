# Persistence and migration

## Responsibility and boundaries

This domain owns the persistence and migration maintenance surface in `tauapi-be`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-be/model/main.go`
- `tauapi-be/model/locking.go`
- `tauapi-be/common/database.go`

Primary/log DB selection -> master AutoMigrate -> shared lockForUpdate transaction -> model mutation -> cache/version publication -> repeat startup and old/new reader checks.

## Consumed and provided contracts

- [backend-release-and-schema](../../../../docs/ai/contracts/backend-release-and-schema.md)
- [authentication](../../../../docs/ai/contracts/authentication.md)
- [billing-and-quota](../../../../docs/ai/contracts/billing-and-quota.md)

## Validation and failure localization

Selected checks: database-matrix, backend-tests. See registry for literal runners and prerequisites.
Inspect schema normalization, reserved-column quoting, driver set compatibility and dialect lock behavior. Real SQLite/MySQL/PostgreSQL and released-schema lifecycle evidence are mandatory for affected behavior.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
