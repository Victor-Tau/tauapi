# Backend engineering obligations

Paths in code spans are relative to `tauapi-be` unless prefixed with `../`.

## Internationalization (i18n)

### Backend (`i18n/`)
- Library: `nicksnyder/go-i18n/v2`
- Languages: en, zh-CN, zh-TW
- Scope: text with no web console in between (errors returned to AI clients, emails, notifications), translated with `i18n.T` / `i18n.Translate`
- Web console API messages are English source text built with `common.NewMessage` / `common.ApiErrorT` / `common.ApiSuccessT`; the frontend translates them, so add each key to all seven frontend locale files
- Stored log content is `[]*common.Message`; a fail reason written by the gateway is a fixed English sentence that is also a key in the frontend locale files
- Server log lines are English text passed through `common.LogText`; `DEFAULT_LANGUAGE=zh-CN` prints the Chinese text of the lines that have one in `common/log_text.zh-CN.json`, and is the language of backend messages for a reader who states none

## Backend rules


**Modern Go conventions:** Apply these conventions to new or modified Go code, including tests and `relaykit/`, when they preserve behavior and improve readability. Use the Go version declared in the relevant module's `go.mod` as the compatibility baseline.

- Use `any` instead of `interface{}`, including map values, slice elements, parameters, and return types.
- For fixed-count loops, prefer `for i := range n`, or `for range n` when the index is unused. For slice indices, prefer `for i := range items`. Keep conventional loops when the bound changes during iteration or the loop needs a different start or step.
- When split results are only traversed once without indexing or reuse, prefer `strings.SplitSeq` or `bytes.SplitSeq` over allocating a slice with `Split`.
- Use `strings.Cut` when splitting at the first separator, and `strings.CutPrefix` / `strings.CutSuffix` when checking and removing a prefix or suffix. Avoid separate searches and manual slicing for the same operation.
- Use `slices.Contains` / `slices.ContainsFunc` for membership checks and `slices.Sort` for natural ordering of ordered element types instead of equivalent hand-written loops or sort callbacks.
- Use `maps.Copy` for shallow map copies and merges. Initialize the destination as needed, and preserve nil-versus-empty behavior and the order in which later values overwrite earlier ones. It does not replace a deep copy.
- Use built-in `min` / `max` for simple bounds instead of equivalent conditional assignments. Preserve numeric semantics; these functions do not prevent overflow in their arguments or replace billing validation and safe quota conversion.
- Use `strings.Builder` for repeated string concatenation in loops; retain direct concatenation for simple fixed expressions.
- Use `reflect.TypeFor[T]()` when the type is known statically, and `reflect.Pointer` instead of `reflect.Ptr`. Keep `reflect.TypeOf` when the dynamic type of a value is required.
- Prefer `sync.WaitGroup.Go` for the standard `Add(1)` / goroutine / deferred `Done()` pattern when its lifecycle and panic contract apply. Preserve existing recovery behavior; the function passed to `Go` must not panic.
- Remove redundant loop-variable copies such as `tc := tc` when they exist only for pre-Go-1.22 closure capture. Retain copies needed for actual snapshot semantics or variables assigned outside the loop.
- Remove ineffective `omitempty` tags on non-pointer struct fields only after confirming the active JSON encoder preserves the same output. Do not change field types or omission behavior as part of a style cleanup; optional relay scalar fields must still follow the pointer rules below.
- Format modified Go files with `gofmt` and remove unused imports after these changes.

**relaykit and tokenkit module independence:** The `relaykit/` and `tokenkit/` Go modules MUST remain independently buildable.

- Code under `relaykit/` or `tokenkit/` MUST NOT import or depend on packages from the root `new-api` module, or rely on root-only configuration, generated files, or workspace wiring. `tokenkit/` also MUST NOT depend on `relaykit/`.
- Any change affecting `relaykit/`, `tokenkit/`, or their public APIs MUST be verified with `GOWORK=off go build ./...` inside that module; a successful root-module build is not sufficient.

**JSON package:** In the root Go module, all JSON marshal/unmarshal operations MUST use the wrapper functions in `common/json.go`:

- `common.Marshal(v any) ([]byte, error)`
- `common.Unmarshal(data []byte, v any) error`
- `common.UnmarshalJsonStr(data string, v any) error`
- `common.DecodeJson(reader io.Reader, v any) error`
- `common.GetJsonType(data json.RawMessage) string`

Do NOT directly import or call `encoding/json` in business code. `json.RawMessage`, `json.Number`, and other type definitions from `encoding/json` may still be referenced as types, but actual marshal/unmarshal calls must go through `common.*`.

Inside `relaykit/`, use `kitutil.*` from `relaykit/relayconvert/kitutil/json.go`, never host `common`. Direct encoder calls belong only in codec implementations.

**Database compatibility:** All database code MUST work with SQLite, MySQL >= 5.7.8, and PostgreSQL >= 9.6 simultaneously.

- Any change that can affect database behavior MUST be verified before the work is considered complete. This includes ORM/database-driver dependency changes, connection/DSN/protocol or prepared-statement configuration, models and GORM tags, migrations and `AutoMigrate`, constraints and indexes, `Scanner`/`Valuer`/serializer behavior, raw SQL, transactions, and row locking.
- Required database verification MUST exercise real SQLite, MySQL, and PostgreSQL instances. Unit tests, mocks, a successful build, code inspection, or testing only one dialect are not substitutes. Use at least one supported version of each engine; changes that depend on version-specific behavior must also cover the minimum supported version.
- Treat GORM core and its database dialect/driver packages as a compatible version set. Any change to one of them requires checking upstream compatibility and running the complete three-database verification matrix; do not upgrade only the core package and infer that existing drivers remain compatible.
- Schema or migration changes MUST be tested both on a fresh database and by upgrading a representative database created by the latest released version. Run startup/migration at least twice to prove idempotency, and verify that existing data, indexes, constraints, and uniqueness guarantees are preserved. Cover the separately configured log database when the affected path is shared with or used by it.
- Record the exact database versions, commands, and results in the final handoff or pull request. If any required database verification cannot be run, report the blocker explicitly and do not claim the change is database-compatible or complete.
- Prefer GORM methods (`Create`, `Find`, `Where`, `Updates`, etc.) over raw SQL.
- Let GORM handle primary key generation; do not use `AUTO_INCREMENT` or `SERIAL` directly.
- Standard `SELECT ... FOR UPDATE` row locks built with GORM query methods in `model/` MUST use `lockForUpdate(tx)`. Do not use the legacy GORM v1 pattern `tx.Set("gorm:query_option", "FOR UPDATE")`, because GORM v2 silently ignores it and no lock is acquired. Do not duplicate `clause.Locking{Strength: "UPDATE"}` at call sites; the shared helper emits `FOR UPDATE` for MySQL/PostgreSQL and skips it for SQLite, where the syntax is unsupported. Dialect-specific locking with different semantics (for example, a MySQL next-key/gap lock) may use raw SQL only behind explicit database-type branches with valid fallbacks for every supported database.
- When raw SQL is unavoidable, account for dialect differences:
  - PostgreSQL uses `"column"` quoting, while MySQL/SQLite use `` `column` ``.
  - Use `commonGroupCol`, `commonKeyCol` from `model/main.go` for reserved-word columns like `group` and `key`.
  - Use `commonTrueVal`/`commonFalseVal` for boolean values.
  - Use `common.UsingMainDatabase(...)` for primary database branches and `common.UsingLogDatabase(...)` for log database branches.
- Do not use database-specific features without cross-DB fallback, including MySQL-only functions, PostgreSQL-only operators, SQLite-unsupported `ALTER COLUMN`, or database-specific JSON column types without a `TEXT` fallback.
- Migrations must work on all three databases. For SQLite, use `ALTER TABLE ... ADD COLUMN` instead of `ALTER COLUMN` (see `model/main.go` for patterns).
- Avoid GORM boolean default tags such as `gorm:"default:true"` when the default is a business rule already enforced by code. MySQL and PostgreSQL can normalize boolean defaults differently, causing GORM `AutoMigrate` to repeatedly issue `ALTER TABLE` on restart. Prefer setting these defaults in request/model normalization, hooks, constructors, or service logic; do not replace `default:true` with `default:1` unless the behavior is verified across SQLite, MySQL, and PostgreSQL.

**Relay and provider behavior:**

- When implementing a new channel, confirm whether the provider supports `StreamOptions`; if supported, add the channel to `streamSupportedChannels`.
- For request structs parsed from client JSON and re-marshaled to upstream providers, optional scalar fields MUST use pointer types with `omitempty` (for example, `*int`, `*uint`, `*float64`, `*bool`).
- Preserve explicit zero values in upstream relay request DTOs: absent client JSON fields must become `nil` and be omitted, while explicit `0`, `0.0`, or `false` values must remain non-`nil` and be sent upstream.
- Avoid non-pointer scalars with `omitempty` for optional request parameters, because zero values will be silently dropped during marshal.

**JavaScript task plugins (mandatory):**

- Before implementing, modifying, or reviewing JavaScript task plugins or their host API/runtime, MUST read [Task Plugin API v1](../plugin-api/v1.md), including its description writing and translation conventions. When changing the plugin contract, also check `docs/plugin-api/v1.schema.json` and `docs/plugin-api/v1.d.ts` for consistency.
- For numeric billing fields in `usageSchema` and `usageProfiles[].schema`, `description` MUST name the **billing subject + unit price**, because it labels the price input in the UI. For example, `image_count` uses `Image generation unit price` / `图片生成单价`, not `Generated image count` / `生成图片张数`; `seconds` uses `Video generation unit price` / `视频生成单价`. The field value remains a usage quantity, not a price.
- Put units in `unit`. Keep protocol limits, usage sources, defaults, estimation, and settlement details in code comments or technical documentation. Descriptions must be short, equivalent across languages, and free of numeric prices and trailing punctuation. Follow the API document's separate wording rules for actions, booleans, and other enum conditions.
- Review metadata wording explicitly before completing plugin work. These are authoring requirements; successful compilation, schema validation, or tests do not verify that descriptions follow them.

**Billing rules (mandatory read gate):** [Billing and quota](../../../docs/ai/contracts/billing-and-quota.md) holds the billing conventions (expression system, built-in pricing, safety invariants, deriving billable quantities from upstream responses). If a task touches billing as defined below, you MUST read that contract in full with your file-read tool — not a grep, a partial skim, memory, or a summary — before planning, coding, or reviewing, and then follow every rule in it. A task touches billing when it meets any of these:

- Edits `pkg/billingexpr/`, `setting/billing_setting/`, `common/quota_math.go`, `types/price_data.go`, `relay/request_billing.go`, `relay/image_handler.go`, `relay/relay_task.go`, `relay/helper/price.go`, `relay/helper/billing_expr_request.go`, `relay/helper/valid_request.go`, `service/quota.go`, `service/text_quota.go`, `service/image_billing.go`, `service/tiered_settle.go`, `service/task_billing.go`, `service/responses_usage.go`, the billing part of `service/log_info_generate.go`, the `model/pricing*.go` / `model/model_pricing*.go` files, or the billing fields and methods of `relay/common/relay_info.go` (`PriceData`, `TieredBillingSnapshot`, `BillingImageCount`, `UpdateImageCount`).
- Reads or writes `PriceData` / `OtherRatios`, quota pre-consume, settlement, refund, or consume-log billing fields anywhere else.
- Derives a billable quantity or `Usage` from an upstream response or stream (image counts, seconds, tokens, task deductions) in any channel adaptor, response handler, or task plugin.
- Validates, bounds, or forwards a request field that becomes a billing multiplier (`n`, `max_tokens`-family fields, duration, resolution or quality, batch counts), including passthrough and multipart paths.
- Adds or changes model prices, or numeric `usageSchema` / `usageProfiles[].schema` fields in a task plugin.

Tasks that touch none of these (for example unrelated frontend work, authentication, database migrations, or protocol conversion that leaves usage untouched) do not need to read it.

**Backend test quality:** Backend tests must protect real behavior, API contracts, billing/accounting invariants, data compatibility, or regression paths.

- **Do not scatter tests for a small change:** For a focused feature or fix, extend an existing suitable test file first. If a new test file is necessary, add at most one and consolidate the key regression cases there. MUST NOT create separate test files for the same small feature across `controller/`, `service/`, `setting/`, or other layers merely because its call chain crosses those layers. Do not repeat fixtures and assertions at each layer. Keep the cases compact and focused on observable behavior; the number of production files touched is not a reason to add more test files.
- Do not add tests that only improve coverage numbers, prove that code happens to run, or lock in implementation details without a user-visible or cross-module contract.
- Avoid fake fuzz/stress/smoke/performance tests built from random inputs, large loop counts, sleeps, timing comparisons, or log-only assertions.
- Avoid duplicate tests that exercise the same branch with different names but no new invariant.
- Avoid tests that force incorrect provider/protocol semantics into production code.
- Avoid tests that assert private constants, select-field lists, helper internals, or file layout when observable behavior is already covered elsewhere.
- Prefer deterministic table tests with explicit inputs and exact expected outputs.
- When tests need database, request context, user group, settings, or cache state, initialize that state explicitly inside the test fixture.
- New or substantially rewritten Go backend tests MUST use `github.com/stretchr/testify/require` for setup and fatal assertions, and `github.com/stretchr/testify/assert` for non-fatal value checks.
- Avoid hand-written assertion helpers unless they encode a reusable project-specific invariant.
- When cleaning tests, preserve meaningful regression coverage. If a deleted test covered a real contract indirectly, replace it with a smaller test that asserts that contract directly.

**Documentation files:**

- Maintain documentation in the root/component `docs/ai/` locations; summarize user effects in root `README.md`, `docs/map.md` or `docs/CHANGELOG.md`. Register new active documents.
- Do NOT create or generate documentation files in this repository's plugin directories under `plugins/`, including `plugins/tasks/<plugin>/` and their subdirectories. This includes README files, changelogs, usage guides, and other documentation files, regardless of format.

## Source map

Paths in this section are relative to the Git root.

### Authentication and authorization

- `tauapi-be/middleware/auth.go`
- `tauapi-be/service/auth_session.go`
- `tauapi-be/service/auth_token.go`
- `tauapi-be/model/user_session.go`

Dashboard route -> credential classification -> JWT/session or PAT validation -> Casbin/scope/proof -> DB session/token state and bounded Redis cache -> response.

- [authentication](../../../docs/ai/contracts/authentication.md)

Selected checks: backend-tests. See registry for literal runners and prerequisites.
Localize 401 at auth version, SID/refresh generation and cache topology; 409 at session mismatch or limits; 403 at declared scope/proof. Protect route-policy coverage, expiry, replay and revoke-others regressions.

### Billing and quota

- `tauapi-be/relay/request_billing.go`
- `tauapi-be/common/quota_math.go`
- `tauapi-be/service/billing_session.go`
- `tauapi-be/service/task_billing.go`
- `tauapi-be/pkg/billingexpr`

Validated quantity -> PrepareRequestBilling -> estimated snapshot and BillingSession -> wallet/token reservation -> upstream usage -> checked conversion -> delta settlement/refund -> saturation audit.

- [billing-and-quota](../../../docs/ai/contracts/billing-and-quota.md)

Selected checks: backend-tests, fixture-equality, billing-go, billing-fe. See registry for literal runners and prerequisites.
Inspect overflow and bypass at multipart/metadata inputs, group retries, image count adjustment and task completion races. Never patch a negative charge by hiding it in presentation.

### Independent libraries

- `tauapi-be/relaykit/go.mod`
- `tauapi-be/tokenkit/go.mod`
- `tauapi-be/relaykit/relayconvert`
- `tauapi-be/tokenkit`

Host prepares model/DTO/media metadata -> RelayKit conversion or TokenKit count -> host transports and accounts usage. Neither library owns sessions, network policy or billing.

- [billing-and-quota](../../../docs/ai/contracts/billing-and-quota.md)

Selected checks: backend-tests, libraries-build. See registry for literal runners and prerequisites.
RelayKit selects request/response/stream conversion by concrete DTO; diagnostics report loss and steps. TokenKit counts supplied text/image dimensions without downloading or parsing host requests. Check each GOWORK=off module build.

### Persistence and migration

- `tauapi-be/model/main.go`
- `tauapi-be/model/locking.go`
- `tauapi-be/common/database.go`

Primary/log DB selection -> master AutoMigrate -> shared lockForUpdate transaction -> model mutation -> cache/version publication -> repeat startup and old/new reader checks.

- [backend-release-and-schema](../../../docs/ai/contracts/backend-release-and-schema.md)
- [authentication](../../../docs/ai/contracts/authentication.md)
- [billing-and-quota](../../../docs/ai/contracts/billing-and-quota.md)

Selected checks: database-matrix, backend-tests. See registry for literal runners and prerequisites.
Inspect schema normalization, reserved-column quoting, driver set compatibility and dialect lock behavior. Real SQLite/MySQL/PostgreSQL and released-schema lifecycle evidence are mandatory for affected behavior.

### Task plugins

- `tauapi-be/pkg/jsplugin`
- `tauapi-be/plugins/tasks`
- `tauapi-be/service/task_polling.go`

Manifest/schema validation -> native route or host protocol -> plugin upstream request -> frozen usage/expression -> immediate result or persisted polling -> guarded complete/fail transition -> settlement/refund.

- [task-plugins](../../../docs/ai/contracts/task-plugins.md)
- [billing-and-quota](../../../docs/ai/contracts/billing-and-quota.md)
- [routing-and-origin](../../../docs/ai/contracts/routing-and-origin.md)

Selected checks: plugins-lint, plugins-format, backend-tests, route-analysis. See registry for literal runners and prerequisites.
Inspect route precedence, profile selection, usage bounds and completion CAS. Duplicate polling and late failures must retain state and accounting semantics; metadata wording requires separate review.

### Relay and providers

- `tauapi-be/router/relay-router.go`
- `tauapi-be/middleware/distributor.go`
- `tauapi-be/controller/relay.go`
- `tauapi-be/relay`

Relay route -> API key -> distributor/channel selection -> controller.Relay -> provider DTO conversion -> HTTP/SSE/WS -> usage normalization and settlement.

- [routing-and-origin](../../../docs/ai/contracts/routing-and-origin.md)
- [billing-and-quota](../../../docs/ai/contracts/billing-and-quota.md)

Selected checks: backend-tests, route-analysis. See registry for literal runners and prerequisites.
Localize protocol loss before changing billing. Check optional scalar pointers preserve explicit zero, stream flushing and plugin fallback JSON 404. Add StreamOptions support only after provider capability review.

## Channel transport settings

Channel JSON settings include `force_format` (normalize to OpenAI format),
`thinking_to_content` (append reasoning content inside `<think>` tags), and `proxy`.
Proxy URLs support `http`, `https`, `socks5` and `socks5h`; saved values require a
scheme and host, an empty or root path, and no query or fragment. SOCKS uses port 1080
when omitted. See `relaykit/dto/channel_settings.go` and `common/proxy_url.go`.

Runtime parsing strips suffixes from legacy saved proxy URLs. It emits one warning per
proxy per process, omitting credentials and suffixes, and leaves the database unchanged.
Saving the channel again requires the strict format. Relay TCP dial timeout and keepalive
are 30 seconds; TLS handshake timeout is 10 seconds, including requests without a proxy.
See `service/http_client.go` and its tests.


## Public version metadata

`controller.GetStatus` exposes the running `common.Version` as `backend_version`
and retains the equal `version` alias for older frontend clients. The API does not
report a frontend version: each frontend bundle owns its independent build metadata.

## Test selection

Only test new or modified packages or cases, one Go module at a time. Full repository
or backend suites and recursive `go test ./...` are prohibited. Use
`make test TEST_MODULE=. TEST_PACKAGES=./path/to/changed-package`, or select `relaykit`
or `tokenkit` as TEST_MODULE with explicit package paths relative to that module.
Build-only acceptance does not launch tests.

## API-only presentation boundary

Do not store, serve or accept frontend branding, layout, navigation, legal/page content,
notices, FAQ, console announcements or chat presets. `common.IsFrontendOption` identifies
retired option keys: model loading ignores historical values, settings reads omit them,
and validation rejects writes before accessing the database. Historical rows are preserved
for rollback; the removed frontend-option migration no longer transforms or deletes them.
Backend service identity in email/log output is independent of frontend branding.

`PublicResourceAccess` is a business API policy, limited to pricing/rankings with boolean
`enabled` and `requireAuth` fields. Root can configure it through `/api/option/`. On load,
only API restrictions are recovered from a historical navigation row if no dedicated policy
exists. No other presentation setting is read. Keep enforcement on the server and test
anonymous, authenticated, disabled-resource and root-management paths.
