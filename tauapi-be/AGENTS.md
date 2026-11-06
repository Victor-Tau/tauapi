# TauAPI backend policy

The root maintenance policy applies. Start at [the local index](docs/ai/INDEX.md).
This directory is one release unit in the TauAPI monorepo; build contexts export
only this subtree. Documentation links may cross components; runtime/build imports may not.

Read [engineering obligations](docs/ai/engineering.md) before modifying or reviewing code.
Read the authentication contract for security work and the billing contract in full
before any billing-impacting planning, coding or review. Billing includes quantities,
usage extraction, prices, passthrough/multipart multipliers, quota and settlement.

## Required contract reads

- [Authentication](../docs/ai/contracts/authentication.md): sessions, PAT, keys, proof and authorization.
- [Billing](../docs/ai/contracts/billing-and-quota.md): prices, usage, reservation, settlement and refund.
- [Routing](../docs/ai/contracts/routing-and-origin.md): page/API split, same origin and fallback.
- [Plugins](../docs/ai/contracts/task-plugins.md): host contracts, metadata and settlement.
- [Frontend release](../docs/ai/contracts/frontend-release.md): immutable assets and old tabs.
- [Backend release](../docs/ai/contracts/backend-release-and-schema.md): migration and rollback.

## Boundaries and validation

Use the toolchain and commands declared in this component, not historic success counts.
Keep New API and QuantumNous identity, licenses, notices and required attribution.
Do not add documentation in `plugins/`; centralize plugin specifications.
Root documentation tooling must never become an application build dependency.
Update domain cards and contracts when their behavior changes.
Record missing prerequisites honestly and reroute the final diff.

RelayKit cannot import the host. TokenKit cannot import the host or RelayKit.
Verify changed libraries with `GOWORK=off go build ./...` in each affected module.
Root JSON operations use `common.*`; RelayKit uses `kitutil.*`.
Database behavior changes require real SQLite, MySQL and PostgreSQL validation;
missing DSNs, skipped tests or a single dialect never satisfy that requirement.
Fresh schema, released-schema upgrades, two startups, data/index/constraint preservation
and affected log databases must be covered. Read the full engineering policy.
