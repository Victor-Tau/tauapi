# 003-release-channel

Status: accepted; implementation: source-inspected.

## Context

TauAPI uses its own version and configurable release repository.

## Chosen approach

Preserve upstream identity in import metadata. Keep local VERSION on upstream integration; compare semantic release versions only.

## Alternatives and consequences

Duplicating authorities or coupling component builds creates drift. Keep cross-component checks at root.

## Supersession

Original decisions remain historical in tauapi-ops/DECISIONS.md; obsolete separate-repository navigation is superseded.

## Sources

- `tauapi-fe/src/features/system-update/releases.ts`
- `tauapi-fe/VERSION`
- `tauapi-be/VERSION`
