# Authentication and authorization

## AUTH-1 Dashboard credentials and session authority

Dashboard requests use a 15-minute JWT access token in browser memory, sent as Bearer,
and an opaque rotating refresh token with at most 30-day lifetime. The server stores
only its HMAC digest. Refresh Cookie is HttpOnly, SameSite=Strict, Path=/api/user/auth.
Gin sessions and New-Api-User are no longer dashboard authentication requirements.
`new_api_has_session=1` is a non-HttpOnly Path=/ hint sharing refresh expiry and clearing;
it carries no credential and never authorizes. Forging it only causes a failed refresh.
The hint avoids wasting IP CriticalRateLimit on anonymous public-page cold starts.

`user_sessions` stores device, IP, login method, activity, expiry and revocation.
The database is authoritative. Security changes to password/status/role/factors increment
`auth_version` and invalidate browser sessions. Subscription group changes refresh
permission caches without logging devices out. SESSION_SECRET derives purpose-separated
JWT/proof/refresh/AuthFlow keys. Production nodes share a high-entropy value; rotation
invalidates sessions, proofs and temporary flows.

## AUTH-2 Multi-instance propagation

All nodes share the primary DB; account session and issuance limits use DB counts.
Redis session hashes include revoking/revoked tombstones and a TTL equal to the smaller
of remaining session life and effective SYNC_FREQUENCY (default/invalid fallback 60 s).
Reads do not renew TTL. Delayed active writes use only the remaining DB observation
window, never restart a full TTL after a tombstone expires. Cache miss/no Redis reads DB.
Shared Redis gives immediate normal revocation/version publication and shared limits.
Separate Redis converges within the effective TTL; new tokens can briefly see 401 on
stale nodes. Rate limits are per node, worst aggregate threshold times node count.
No Redis validates each session in DB but uses per-node memory limits.
Smaller TTL increases per-SID DB reads. Shared Redis also requires common CRYPTO_SECRET
for matching cache-key digests. These bounded-staleness guarantees cover session auth,
not every cache or the entire control plane.

## AUTH-3 Browser bundle and refresh concurrency

Password, 2FA, Passkey, OAuth, WeChat and Telegram logins return AuthBundle data:
access_token, token_type=Bearer, access_expires_at, user and session (sid, current,
login_method, ip, user_agent, created_at, last_active_at, expires_at).
POST /api/user/auth/refresh rotates refresh and returns access; logout revokes and clears.
GET /api/user/sessions lists at most 100 current-auth-version effective sessions, current first.
DELETE /api/user/sessions/:sid may revoke current; revoke-others preserves current.

When memory has a SID, refresh/logout send X-Auth-Session. Cookie/SID mismatch returns
409 AUTH_SESSION_MISMATCH without rotating, revoking or clearing. Clear stale memory,
refresh once without old SID, then retry logout. Cold start may omit SID.
Concurrent refresh reuses a deterministic successor so losing a winner response does not
log out another tab. Reuse of the immediately previous generation after tolerance revokes
the session; unknown older/random values only fail and cannot be guessed to revoke it.
Web Locks serialize browser-profile refresh. BroadcastChannel or storage-event fallback
carries only SID and login/logout events, never access/refresh tokens. Tokens are not
persisted in Web Storage. Never replay one-time proof actions automatically.

Cold-start state differs from login state. Temporary network/server failures permit later
refresh retry; only confirmed invalid refresh completes anonymous state. Public pages skip
refresh without hint or memory, but that skip is deferred discovery, not a server conclusion.
Protected routes and sign-in always refresh empty memory regardless of hint, allowing older
valid Cookies or cleared root storage to restore. A stale hint is cleared with the invalid
refresh response so its wasted request happens once.

## AUTH-4 Issuance and retention

USER_SESSION_ACTIVE_LIMIT defaults 50: excess new login returns 409 AUTH_SESSION_LIMIT.
USER_SESSION_ISSUANCE_LIMIT defaults 100 per USER_SESSION_ISSUANCE_WINDOW_SECONDS=86400;
count all created sessions including revoked/old versions; excess returns 429
AUTH_SESSION_ISSUANCE_LIMIT. Counts+insert have no cross-database lock; extreme concurrent
logins can slightly exceed limits. Count failure rejects issuance. Existing excess sessions
are not evicted. USER_SESSION_REVOKED_RETENTION_DAYS defaults 7; clamp issuance window to
retention with startup warning. Cleanup preserves rows still in issuance window and revoked
rows still in retention even when expired. Stale auth-version active rows count toward limit
but are hidden from device lists. Revoke-others clears them; password reset revokes all but
does not reset issuance counts. Only master cleans hourly in batches.
USER_SESSION_HOURLY_ALERT_THRESHOLD=5000 logs anomaly, never globally denies login.

## AUTH-5 Cookie Origin and proxy boundaries

SESSION_COOKIE_SECURE unset/false supports trusted local HTTP and disables refresh/logout
OriginGuard; SESSION_COOKIE_TRUSTED_URL must be unset. Never expose this mode publicly.
Secure=true requires HTTPS Cookie transport and exact Origin validation on both POSTs;
only a valid single Referer substitutes absent Origin. Accept exact request origin plus
configured trusted origins. Do not trust client X-Forwarded-Proto. TLS proxies require
explicit public HTTPS origin in SESSION_COOKIE_TRUSTED_URL. Comma-separated entries are
exact HTTPS origins (optional port), no wildcard/path/query/userinfo/suffix match.
This is not CORS configuration and does not change relay/legacy billing dashboard or
/api/usage/token and /api/log/token CORS. Relay sk-key browser calls retain semantics.

TRUSTED_PROXIES unset/empty/whitespace defaults to 127/8, ::1, 10/8, 172.16/12, 192.168/16,
fc00::/7 with warning. Public direct clients cannot spoof forwarded IP. `none` alone,
case-insensitive, trusts no proxy. Explicit comma-separated proxy IP/CIDRs replace defaults;
invalid/empty/mixed-none lists stop startup. List proxies, not client networks.
Gin trusts headers only from trusted immediate peers, scanning the chain right-to-left
until an untrusted address; private peers remain a spoofing risk under defaults.
Configure exact peers or none to remove that risk. CGNAT/link-local/custom CNI need explicit config.
Redis IP limits use atomic Lua fixed windows: adjacent boundaries can admit twice threshold
(e.g. 40 around a 20/20-minute boundary). Model-success user limits retain approximate sliding
Redis Lists, now UTC timestamps. Old local/new UTC strings cannot be distinguished during
rolling upgrade and can mis-admit/reject for one full window after the last node upgrades.
No key reset occurs. Public signup also needs Turnstile/email verification; IP limits alone
cannot stop distributed multi-account attacks.

## AUTH-6 PAT and server authorization

PAT accepts Bearer or one Authorization value, never URL parameters or New-Api-User.
Format nap_ plus 43 base62 characters (~256 bits); plaintext returned once, DB SHA-256 digest
is also audit token_ref. Up to 20 per user in user_access_tokens. Creation selects scopes
and expiry: default 30 days, minimum 1 hour; never-expiring is allowed with UI warning.
Expired tokens fail immediately; master cleans beyond retention. Scopes resource:action
follow the catalog and Casbin admin matrix. Grant only current permissions; every request
re-reads role/permissions, so withdrawn admin grants immediately remove capability.
Every dashboard route declares scope; missing ->403 ACCESS_TOKEN_ROUTE_UNDECLARED,
insufficient ->403 ACCESS_TOKEN_SCOPE_DENIED, expired ->401 ACCESS_TOKEN_EXPIRED.
PAT cannot create/rename/revoke PAT or manage browser sessions. PAT can obtain proof when
holding channel:secret_view for channel.key.read, user:write for admin.user.*, or
account_security:write for own password/2FA/Passkey/bindings/deletion; OAuth proof is forbidden.
PAT security changes revoke browser sessions but preserve that PAT. Disabled users cannot
use tokens; re-enable restores them; delete/account removal deletes tokens.
Last-used time/IP updates at most once per minute; update failure does not fail the request.

## AUTH-7 Temporary flows and proofs

AuthFlow stores OAuth state, 2FA pending, Passkey ceremony and Telegram binding; client holds
random flow_token and DB only HMAC digest. Bind purpose/provider/intent/user/session and
atomically consume once. OAuth affiliate code travels with login AuthFlow.
OAuth binding popup sends same-origin postMessage to opener; opener alone calls binding
with its in-memory Bearer. Telegram binding requires a logged-in-created flow, callback
flow_token and rechecked session; signed widget assertions are also one-time credentials.

X-Security-Proof expires after 1 minute, binds user, session (PAT itself for PAT), auth
version, session version and scope; cannot cross users/sessions/purposes. Protected actions:

| Scope | Context and trigger |
| --- | --- |
| channel.key.read | view channel secret |
| passkey.register | 2FA user registration begin+finish, recheck before flow consume |
| passkey.delete | remove Passkey |
| admin.user.delete | user_id; DELETE user or manage delete |
| admin.user.manage | user_id/action disable, enable, promote, demote; add_quota exempt |
| admin.user.update | user_id when new password/admin_permissions; display/group/notes exempt |
| admin.user.create | role when creating administrator; ordinary user exempt |
| admin.user.passkey.reset | user_id |
| admin.user.2fa.disable | user_id |
| admin.user.binding.clear | user_id and binding_type or provider_id |

Admin scopes issue only to admin-or-higher. Enabled 2FA/Passkey requires one of them;
otherwise password or bound OAuth reauth; disabled password login forbids password proof.
PAT requires user:write and proof for admin actions; legacy PAT cannot call them.
First Passkey registration without 2FA needs no proof.

## AUTH-8 Upgrade and verification

Old session Cookie is retired and old browser logins must reauthenticate. Migrations add
user_sessions, auth_flows, external_identity_claims, users.auth_version; initialize versions
and unique Telegram ownership. Duplicate Telegram owners stop migration pending resolution.
Issuance/cleanup indexes may need a first-start maintenance window on large session tables.
previous_refresh_hash migrates char(64) -> varchar(64), tolerates old padding and must be
idempotent on repeated startup. Master alone cleans sessions and expired retained flows.
Clients upgrade AuthBundle/flow/proof contracts; PAT clients remove New-Api-User.
Legacy users.access_token lasts 30 days from first new startup; retirement time is server-owned
LegacyAccessTokenRetireAt option, not writable through settings. Then 401
ACCESS_TOKEN_LEGACY_RETIRED. Cannot mint legacy tokens; revocation remains possible.
/api/user/token* is removed in favor of /api/user/access_tokens. Downgrade disables new PATs
and revives unrevoked legacy PATs because old code ignores retirement date.

Sources: middleware/auth.go; service/auth_session.go; service/auth_token.go;
service/authz; model/user_session.go; frontend lib/http-client.ts, lib/auth-session.ts,
lib/auth-session-sync.ts and stores/auth-store.ts. Paths are component-relative.
Retain TestAccessTokenRouteRulesCoverEveryDashboardRoute and session/token failure, expiry,
replay and revocation tests. Apply latest stable OWASP ASVS and relevant Authentication,
Session, Password Storage, Recovery, MFA, OAuth and CSRF cheat sheets before security changes;
identify controls, enforce server-side, omit credentials from audit, record references/version/IDs
and regression evidence. This migration is source review, not a new security certification.
