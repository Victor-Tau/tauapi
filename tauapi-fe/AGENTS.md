# TauAPI frontend policy

The root maintenance policy applies. Start at [the local index](docs/ai/INDEX.md).
This directory is one release unit in the TauAPI monorepo; build contexts export
only this subtree. Documentation links may cross components; runtime/build imports may not.

Read [engineering obligations](docs/ai/engineering.md) before modifying or reviewing UI.
For UI work read `.agents/skills/shadcn-ui/SKILL.md`, search shared business wrappers,
and inspect candidate implementations and call sites before introducing a component.
The preserved `UPSTREAM_ROOT_AGENTS.md` is provenance, not an always-loaded entry.
Applicable security, attribution and contribution rules are linked below.

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

Use Bun and React/TypeScript, TanStack routing/query, and existing shared components.
Use relative business URLs and the shared HTTP client; tokens stay out of Web Storage.
Use flat English i18n keys; convert interface languages with `toIntlLocale`.
Run typecheck for TS/TSX edits, relevant behavior tests, and lint on changed code.
A fixture snapshot is synchronized from the backend by root tooling; builds consume
only the local snapshot. UPSTREAM.json remains immutable import provenance.

Common code quality, OWASP authentication, attribution, issue and PR obligations
are maintained in [shared engineering rules](../tauapi-be/docs/ai/engineering.md).
Read their applicable sections before affected work. No sibling build dependency is introduced.
