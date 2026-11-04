# Repository split (tauapi)

This directory (`tauapi-be/` of the TauAPI monorepo) is the **API-only backend** of New API (QuantumNous/new-api),
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
- Branches (TauAPI monorepo, this tree lives under `tauapi-be/`): `vendor/upstream-be` holds raw imports only (linear, one commit per
  upstream SHA); `main` carries the customisations and merges new imports into `tauapi-be/` via
  `upgrade/<short-sha>` branches (`tauapi-ops/scripts/sync-upstream.sh`).

Upstream README build instructions that mention `web/` refer to the combined
upstream repository and do not apply here.

## Release notes

- `be-r2`: no functional change versus the initial API-only split; rebuilt to
  exercise the drained master/slave rolling release and rollback procedure
  (the image version string carries the new backend commit).
