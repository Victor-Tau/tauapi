# 001-release-boundaries

Status: accepted; implementation: source-inspected.

## Context

Separate repositories were replaced by monorepo decision19.

## Chosen approach

Keep one Git history and two independently archived release units. Backend is API-only.

## Alternatives and consequences

Duplicating authorities or coupling component builds creates drift. Keep cross-component checks at root.

## Supersession

Original decisions remain historical in tauapi-ops/DECISIONS.md; obsolete separate-repository navigation is superseded.

## Sources

- `tauapi-ops/scripts/build-frontend.sh`
- `tauapi-ops/scripts/build-backend.sh`
- `tauapi-be/main.go`
