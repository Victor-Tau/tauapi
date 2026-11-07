# Routing and origin

## Intended behavior and invariants

RTE-1: `tauapi-ops/ROUTE_CONTRACT.json` owns the Nginx page/asset split data.
Explicit page routes receive the SPA; backend exceptions such as dashboard billing
precede page prefixes. All other paths reach backend dispatch, including native plugins.
RTE-2: API fallback attempts plugin dispatch before uncached JSON 404, never SPA HTML.
Do not add fallback cache headers to successful plugin responses or break stream flushing.
RTE-3: Business HTTP uses relative same-origin URLs. Reserved `/_ui/`, `/_meta/`, ACME
and registered frontend pages cannot be claimed by plugins. Missing immutable assets return 404.

Changed routes require contract-data review, direct navigation/reload tests, backend fallback
and plugin reachability tests. Regex plugin scanning is partial evidence; runtime registrations
can be dynamic. The static checker reports literal frontend omissions; dynamic coverage is a gap.
Do not maintain another exhaustive route table.

## Sources and change procedure

- `tauapi-ops/ROUTE_CONTRACT.json`
- `tauapi-ops/scripts/generate-nginx.py`
- `tauapi-be/router/main.go`
- `tauapi-be/router/plugin-router.go`
- `tauapi-fe/src/routes`
