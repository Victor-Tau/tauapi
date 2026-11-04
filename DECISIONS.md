# DECISIONS

1. **Executor environment**: running directly on the target host as user `tau` with sudo (password-based; supplied by the user, cached for askpass in `~tau/.config/newapi-sudo/pw` 0600, removed at handoff). `tau` is NOT added to the docker group; docker is invoked through sudo.
2. **Upstream source**: `/home/tau/new/new-api-official` clone (user statement said `/new-api-official`; the actual path is under /home/tau/new). Pinned SHA was re-fetched from GitHub into `/var/cache/newapi/upstream` and verified; no floating main.
3. **Certificate**: no contact email provided → `certbot --register-unsafely-without-email` (GOAL §1.3). Ubuntu apt certbot 2.9.0 (single install method) with systemd `certbot.timer`; deploy hook `nginx -t && reload`.
4. **Bootstrap ordering deviation**: the certificate was issued while the host served only the ACME path and a static 503 maintenance page; no New API process existed yet, so nothing uninitialised was exposed (§13.1 satisfied).
5. **Swap**: 3.8 GiB RAM and no swap → 4 GiB `/swapfile` (fstab) for bun/rspack + Go builds; heavy builds serialized.
6. **Toolchains**: Go 1.26.10 and Bun 1.4.4 official tarballs, sha256-verified, in `~tau/.local/toolchains` for local checks; release images built in pinned-digest builder images.
7. **Backend API-only**: removed go:embed, HTML analytics injection, SetWebRouter, ServeFrontendFiles, EmbedFolder, Cache() (front-end-only). NoRoute = pluginDispatcher → RouteTag(fallback) → AccessTokenAudit → GlobalWebRateLimit → RelayNotFound (uncached JSON 404). `FRONTEND_BASE_URL` redirect mode dropped (frontend is served by Nginx on the same origin).
8. **Analytics**: not configured → not enabled. Placeholders in index.html stay inert comments.
9. **Database**: PostgreSQL 16 (supported until Nov 2028), Redis 7 (stable), images pinned by digest at deploy time.
