# 002-runtime-isolation

Status: accepted; implementation: source-inspected.

## Context

Production and QA need distinct data/secrets/ports.

## Chosen approach

Keep QA on loopback, separate compose names and volumes. Preserve deploy lock and isolated restore.

## Alternatives and consequences

Duplicating authorities or coupling component builds creates drift. Keep cross-component checks at root.

## Supersession

Original decisions remain historical in tauapi-ops/DECISIONS.md; obsolete separate-repository navigation is superseded.

## Sources

- `tauapi-ops/scripts/lib.sh`
- `tauapi-ops/templates/compose.yml`
