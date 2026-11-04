# Repository split (newapi-victor)

This repository is the **API-only backend** of New API (QuantumNous/new-api),
imported from a pinned upstream commit recorded in `UPSTREAM.json`.

- Imported: everything from upstream except `web/` (now the separate frontend
  repository) and `electron/` (desktop shell, not deployed here).
- `relaykit/`, `tokenkit/`, `plugins/` (including the JavaScript task plugins),
  `i18n/`, `e2e/`, docs, licenses and agent rules are kept unchanged.
- The default build embeds no dashboard: `main.go` has no `go:embed`, the router
  registers backend routes only, and unmatched requests go through the dynamic
  plugin dispatcher and end in an uncached JSON 404.
- `FRONTEND_BASE_URL` redirect mode and the HTML analytics injection were removed;
  analytics, if ever enabled, belong to the frontend build.
- Plugin lint/format moved from the frontend `package.json` to
  `make lint-plugins`, `make format-plugins`, `make format-plugins-check`.
- Branches: `vendor/upstream` holds raw imports only (linear, one commit per
  upstream SHA); `main` carries the customisations and merges new imports via
  `upgrade/<short-sha>` branches. See the ops repository `scripts/sync-upstream.sh`.

Upstream README build instructions that mention `web/` refer to the combined
upstream repository and do not apply here.
