# Routing

## Responsibility and boundaries

This domain owns the routing maintenance surface in `tauapi-ops`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-ops/ROUTE_CONTRACT.json`
- `tauapi-ops/scripts/generate-nginx.py`

ROUTE_CONTRACT -> generate-nginx -> reviewed config -> nginx -t -> authorized switch -> page/API/plugin/cache/404 observations.

## Consumed and provided contracts

- [routing-and-origin](../../../../docs/ai/contracts/routing-and-origin.md)

## Validation and failure localization

Selected checks: route-analysis. See registry for literal runners and prerequisites.
Inspect backend-exceptions-first ordering and reserved namespaces. Literal regex scanning is partial coverage; test dynamic plugin reachability separately.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
