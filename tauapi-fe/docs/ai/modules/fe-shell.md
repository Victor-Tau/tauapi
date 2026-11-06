# Shell and routing

## Responsibility and boundaries

This domain owns the shell and routing maintenance surface in `tauapi-fe`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-fe/src/routes`
- `tauapi-fe/src/routeTree.gen.ts`
- `tauapi-fe/src/lib/legacy-route.ts`

TanStack file route -> generated routeTree -> layout/beforeLoad -> feature section -> same-origin query. Nginx must serve the page before the browser router can run.

## Consumed and provided contracts

- [routing-and-origin](../../../../docs/ai/contracts/routing-and-origin.md)
- [frontend-release](../../../../docs/ai/contracts/frontend-release.md)

## Validation and failure localization

Selected checks: frontend-typecheck, frontend-tests, frontend-build, route-analysis. See registry for literal runners and prerequisites.
Direct-load/reload failure usually indicates route split drift; in-app-only success does not prove server routing. Keep legacy redirects, search validation and generated route-tree provenance coherent.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
