# Component policy

> Template target: one component's AGENTS.md. Fill the fields below, remove
> irrelevant rules, and retain applicable inherited constraints before activation.

## Responsibility

Component: `REPLACE_COMPONENT`.
Owns: `REPLACE_RESPONSIBILITY`.
Does not own: `REPLACE_BOUNDARY`.

The root agent policy applies. This file adds local rules and does not override
global or cross-component invariants. Read this component's `docs/ai/INDEX.md`
and the relevant domain card before editing.

## Source and validation

Use the component index to find source entry points and canonical commands.
Every command must specify its working directory and required environment.
Read adjacent existing tests before creating new regression coverage.

## Local invariants

Replace this section with concise, verified component-specific rules. Keep
full contract text in its canonical document and link invariant IDs here.

For the backend, preserve three-module validation and API-only behavior.
For the frontend, preserve shared-component reuse, i18n, and relative API access.
For operations, preserve deployment locking, environment selection, and recovery
semantics. Do not present these sample lines as the complete local policy.

## Cross-component changes

Re-route changes affecting request/response shape, permissions, usage, schema,
routes, assets, or release compatibility. Read affected sibling-domain contracts
from the full repository before implementing the integration.

## Documentation impact

Update the domain card only when its facts change. Record contract dispositions
and relevant Chinese user-guide updates in the task record.
