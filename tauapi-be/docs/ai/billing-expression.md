# Billing Expression System (billingexpr)

## Design Philosophy

**One expression, one truth.** A single expression string completely defines a model's billing logic — pricing, tier conditions, cache/image/audio differentiation, time-based discounts, request-aware multipliers — all in one line. No scattered configuration, no implicit rules, no magic numbers.

The expression is the billing contract between the administrator and the system. What you write is what gets executed. The system's job is to evaluate it faithfully, not to interpret it.

### Core Principles

1. **Expression is self-contained** — The expression string alone determines billing. No external ratio tables, no implicit completion multipliers, no hidden conversion factors. Given the same token counts and request context, the same expression always produces the same cost.

2. **Variables are opt-in** — `p` (prompt) and `c` (completion) are the base. Cache (`cr`, `cc`, `cc1h`, `cc12h`), image (`img`), and audio (`ai`, `ao`) variables are optional. If omitted, those tokens are included in `p`/`c` and priced at their rate; an omitted long-lived cache write keeps its fixed multiple of the short write price. The system automatically detects which variables the expression uses (via AST introspection) and adjusts token normalization accordingly.

3. **Prices are real prices** — Token coefficients are actual $/1M tokens prices as published by providers. `p * 2.5` means $2.50 per 1M prompt tokens; `fixed(0.01)` means $0.01 per request. No ratio conversion or `/2` convention is required.

4. **Upstream-agnostic** — The expression doesn't need to know whether the upstream API is OpenAI-format (prompt_tokens includes cache) or Claude-format (input_tokens excludes cache). The system normalizes token counts before evaluation based on the upstream response format.

5. **Version-aware** — Expressions carry a version tag (`v1:`, default when omitted). The version controls the compile environment, token normalization, and quota conversion formula, enabling future evolution without breaking existing expressions.

---

## Expression Language

Powered by [expr-lang/expr](https://github.com/expr-lang/expr). Expressions are compiled, cached, and evaluated against a runtime environment.

### Token Variables

Input variables: p is input tokens priced at the base rate; len is full input context for
conditions; cr is cache read; cc is generic/Claude 5-minute/OpenAI 30-minute cache creation;
cc1h is Claude 1-hour; cc12h OpenAI 12-hour; img image input; img_cr valid separately reported
image cache read; ai audio input. Output c is base output, img_o image output, ao audio output.
Only referenced separately priced categories are subtracted from p/c to avoid double charging.
Use len for context tiers: raw prompt_tokens for OpenAI, text+cache read+creation for Claude.
For input 1000 (200 cache,100 image), p is 1000 without categories, 800 with cr, 700 with cr+img.
For output 500 (100 audio), c is 500 without ao, 400 with ao. Unpriced long cache writes cost
2 times short write for OpenAI 12h, 6/3.75 times for Claude 1h; short price is cc or p fallback.
Claude separately reported caches are added back when unpriced, never subtracted twice.

#### Image cache compatibility

OpenAI-compatible usage.input_tokens_details.cached_tokens_details may report text/image/audio.
Preserve missing vs explicit zero through DTO copying, usage merging and billing conversion.
Synthetic compatible fixtures do not prove real upstream Images cache payload support.
When img_cr is referenced and valid, remove it from both cr and img before subtracting disjoint
categories from p. len stays raw. For total1000/image600/cache300/image-cache200: expression
p*5+cr*1.25+img*8+img_cr*2+c*30 yields p300/cr100/img400/img_cr200 and $0.008225 at output100.
Missing details: img_cr=0, cr keeps generic cache, never infer split. Unreferenced img_cr preserves
old behavior. Negative/over-total/impossible details emit diagnostics and fallback. Anthropic
uses its independent cache semantics. Consume logs for img_cr pricing store image_cache_tokens
and actual billing_tokens through shared text/audio/realtime injection. Evaluation failure with
reservation fallback must not invent actual usage; fixed/unreferenced expressions add no fields.
cache_tokens remains upstream total. Images output_tokens means image output; built-ins use c
without requiring output_tokens_details.image_tokens.

### Legacy pricing conversion

Legacy ratio/per-call remain usable but deprecated; new pricing defaults to expressions.
POST /api/option/model_pricing/convert accepts model_name and complete pricing draft, inheriting
missing keys from runtime defaults. Returns expression/effective snapshot or precise unsupported
reason, without DB write. Preview uses that snapshot; confirmation changes draft, cancel preserves.
PATCH /api/option/model_pricing with expected_version still performs save/conflict checks.
Base USD/million = ModelRatio*1000000/QuotaPerUnit; retain output/cache/image ratios and explicit zero.
Per-call -> tier("request", fixed(price)); retain legacy fields to switch back. Expression reservation
and rounding need not match legacy rounding per request. Shared effective-price resolver uses
model-family forced/fallback output ratios; absent cache-read/write/image use 1/1.25/1.
Image ratio1 omits img; other ratios including zero emit img. Cache-read1 merges in preview and
omits cr when no separate image/write term. With overlapping categories retain cr calculation
because zero-floor input remainder prevents equivalence; hide equal-price row instead.
Base input zero may omit cr at ratio1; other ratios including zero preserve it. Omitted Claude
cache-read adds back to p while len remains full. Cache-write categories depend on public billing
name and original config: case-insensitive claude emits cc/cc1h at CreateCacheRatio*6/3.75;
other names emit cc only if configured (including zero); gpt also cc12h at twice ratio.
Generic unconfigured 1.25 fallback adds no new term. Do not infer categories from channels,
whitelists or require admin selection. Read-only cache_write_mode is none/standard/claude_ttl/openai_ttl.
Preview response is {success,message,data:{effective,cache_write_mode,billing_details}};
snapshot/convert structures unchanged. Metadata is not stored/evaluated. Unset differs from zero;
disabled draft overrides use post-save fallback, not stale current process settings.
Image and ordinary audio can convert; task/video/Realtime and OpenRouter Claude cost-derived
cache writes return precise unsupported reasons, not blanket channel/unknown-endpoint bans.
Gemini ai uses actual legacy USD without input ratio, even with zero base price. Other audio ai
is base*AudioRatio, ao additionally AudioCompletionRatio, absent=1, explicit zero preserved.
Audio settlement ignores cache/image ratios: conflicting configuration generates separate audio
and text branches. Audio ordinary input uses max(len-ai,0), isolated from text cache variables.
Gemini text retains zero-floor after cache/audio overlap. Read-only billing_details supplies actual
audio price/image quantities/request multipliers, not new stored price authority. Conflicting prices
across Gemini/compatible audio reject conversion with specific reason, never silently select one.
Image per-call -> tier("image",fixed(price))*image_count plus legacy size/quality factors.
DALL-E factors derive original request model, not mapped model. Legacy rules stay in dedicated
files for historical/compatible providers; conversion reads DTO rules, never a second price table.
Image token pricing does not additionally multiply count; expression freezes prices/factors and
must not reapply legacy OtherRatios.

### Image Quantity

image_count is independent of token count, default1 without context; supplied integer in
1..dto.MaxImageN=128. Fixed-price grammar allows count but never token multiplication.
Parse provider scalars once at image entry; top-level n (0 ->1) determines billing.
parameters.n remains validated but does not override billing count. After retry/override revalidate
final upstream count and raise reservation before sending; atomic wallet checks prevent deficit submission.
estimated_image_count records outgoing quantity. JSON/multipart context keeps billing scalars only,
never images/prompts. Actual count does not mutate frozen param("n"). Completed SSE can reduce
charge, client abort cannot. Consume logs include image_count. Alibaba openai_image host protocol
uses task u("image_count"): reserve request count, settle bounded usage.image_count or Qwen-Image-3.0
usage.output_image_count, otherwise payloads across choices message content/results. Task logs also record it.

### Built-in Functions

| Function | Signature | Purpose |
|----------|-----------|---------|
| `tier` | `tier(name, value) → float64` | Records which pricing tier matched; must wrap the cost expression |
| `fixed` | `fixed(amount) → float64` | A USD price per request, used only as the complete price in `tier(name, fixed(amount))` |
| `param` | `param(path) → any` | Reads a JSON path from the request body (uses ojson, gjson path syntax) |
| `header` | `header(key) → string` | Reads a request header value |
| `has` | `has(source, substr) → bool` | Substring check |
| `hour` | `hour(tz) → int` | Current hour in timezone (0-23) |
| `minute` | `minute(tz) → int` | Current minute (0-59) |
| `weekday` | `weekday(tz) → int` | Day of week (0=Sunday, 6=Saturday) |
| `month` | `month(tz) → int` | Month (1-12) |
| `day` | `day(tz) → int` | Day of month (1-31) |
| `max` | `max(a, b) → float64` | Math max |
| `min` | `min(a, b) → float64` | Math min |
| `abs` | `abs(x) → float64` | Absolute value |
| `ceil` | `ceil(x) → float64` | Ceiling |
| `floor` | `floor(x) → float64` | Floor |

### Expression Examples

```
# Simple flat pricing
tier("base", p * 2.5 + c * 15 + cr * 0.25)

# Conditional per-request pricing, with token pricing for the fallback
len <= 32000
  ? tier("short", fixed(0.01))
  : tier("long", p * 2 + c * 8)

# Multi-tier (Claude Sonnet style) — use len for tier conditions
len <= 200000
  ? tier("standard", p * 3 + c * 15 + cr * 0.3 + cc * 3.75 + cc1h * 6)
  : tier("long_context", p * 6 + c * 22.5 + cr * 0.6 + cc * 7.5 + cc1h * 12)

# Image model (no separate cache/audio pricing — those tokens stay in p/c)
tier("base", p * 2 + c * 8 + img * 2.5)

# Multimodal with audio
tier("base", p * 0.43 + c * 3.06 + img * 0.78 + ai * 3.81 + ao * 15.11)
```

### Fixed Request Prices

`tier("request", fixed(0.01))` replaces all token charges in the selected leaf
with a $0.01 base price for one successful HTTP/SSE request. Other leaves may
still use token pricing. Group ratios and request multipliers continue to apply;
existing tool surcharges are calculated separately and added as before. A stream
does not incur a fixed fee per chunk. Realtime and task usage expressions reject
`fixed()` before upstream submission or reservation.

The amount must be a finite, non-negative numeric literal whose v1 scaled value
is finite. Explicit `fixed(0)` is valid and stays free. Expressions using `fixed`
must consist of a conditional pricing tree and the standard request multiplier
factors described below, with each leaf wrapped in `tier()`. Adding fixed and
token charges in one leaf, adding multiple tiers together, or multiplying a
fixed price by tokens is rejected. Validation examines the original AST,
including branches that optimization or short-circuiting would skip. Existing
expressions without `fixed()` retain their original grammar and behavior.

`fixed(amount)` returns `amount * 1,000,000` internally, preserving v1's existing
quota conversion and rounding. Pre-consume matches conditions using estimates;
settlement reevaluates against actual or existing locally estimated usage and
reconciles any change of branch through the normal billing session. Missing
upstream usage retains the existing estimation path; an actual request-priced
branch can charge even with zero tokens. Failures retain the normal refund
policy. Settlement evaluation errors retain the reservation and its estimated
billing unit.

Evaluation results expose `billing_unit` (`token` or `request`) and, for a
request-priced leaf, `fixed_price` in USD before multipliers. Pre-consume snapshots
carry `estimated_billing_unit` and `estimated_fixed_price`; consume logs append
the actual values to `other`. An explicit zero price is present in these fields.
Older snapshots and logs need no migration. The expression remains the sole
pricing configuration.

### Request Rules (appended after `|||`)

Request-conditional multipliers are appended to the expression after a `|||` separator:

```
tier("base", p * 5 + c * 25)|||when(header("anthropic-beta") has "fast-mode") * 6
```

These factors are stored as ordinary multiplication in the final expression (for example, `(tier(...)) * (condition ? 6 : 1)`) and run in the same billing program.

### Request Rule Tracing

At compile time, the engine instruments ternary factors with this exact shape:

```
<request-probe condition> ? <numeric literal> : 1
```

The condition must reference at least one request probe (`param`, `header`, `hour`, `minute`, `weekday`, `month`, or `day`). Both branches must be numeric literals and the fallback must equal `1`. Other conditionals, including `(condition ? 2 : 1.5)`, are evaluated normally but are not traced. Integer-only factors use an integer-preserving trace callback, so instrumentation does not change expressions that require an integer operand (for example, `%`). The internal trace callback names are reserved and cannot be used in stored expressions.

The compiled cache stores the canonical condition and multiplier for every instrumented node. Each run starts with the full detected rule list marked as unmatched; callbacks mark rules that actually evaluate true. Rules skipped by normal expression short-circuiting remain unmatched. This keeps the expression's numeric result unchanged and avoids reparsing it on each request.

Settlement copies the actual run's traces into the consume log as:

```json
{
  "request_rules": [
    { "cond": "param(\"service_tier\") == \"fast\"", "multiplier": 2, "matched": true }
  ]
}
```

The usage-log UI treats `request_rules` as the authoritative rule list and renders directly from it. It parses `cond` only to produce a friendly label and falls back to the canonical condition text when that parser does not recognize the condition. Pricing pages without log context continue to parse the stored expression for display.

---

## Task Usage Expressions

Task plugins can expose validated, provider-specific billing facts through
`meta.usageSchema`. Expressions read those facts with `u("key")`. A literal key
must be declared by the plugin schema before the expression can be saved. A
single-plugin model's unchanged stored expression, and its unchanged provider
override, stay saveable after the plugin narrows the model's profile; any edit
must follow the current profile.

Multiple plugins may serve the same model with different usage schemas. The
executing channel identifies the plugin; clients do not select a billing
provider. Task expression resolution uses this order:

1. `billing_setting.plugin_billing_expr["<pluginKey>::<clientModel>"]`
2. The same plugin's override for the final mapped model, when present
3. The client model's expression when its billing mode is `tiered_expr`
4. The final mapped model's expression when the client model has no expression
   billing mode

Plugin overrides always use task-usage semantics, independently of the model's
billing mode. The flat override map is a separate option and never contributes
composite keys to model names or model-price synchronization exports. Existing
prices are not rewritten. The billing snapshot freezes the selected expression;
completion uses that snapshot even if provider pricing later changes.

A model-level expression save smoke-tests each candidate's selected schema,
skipping candidates with their own override in the same complete draft.
Provider expression saves validate the plugin/model binding and that plugin's
schema; errors identify both model and plugin. For a shared model, an effective
expression referencing an undeclared literal `u()` key is unconfigured for that
provider, including references in branches skipped by the current request.
Submission rejects it with 400 `model_price_error`; administration and public
pricing expose the unconfigured state. Public model-level metadata remains the
first plugin's view in ascending key order, with provider variants added
separately.

Saved provider overrides remain visible when only one provider remains.
Administration exposes unavailable plugin/model bindings as `stale` and permits
preserving or removing their existing expressions. Changes to those expressions
still require a valid binding; writes compare against the locked database
snapshot rather than the process cache. No overrides are silently pruned.
Public provider variants include their effective `billing_mode` so inherited
ratio/per-call pricing is distinct from an unconfigured usage expression.

Plugins serving different model families can optionally declare
`meta.usageProfiles: [{models: ["image-model"], schema: {...}, examples: [...]}]`.
Each profile provides the complete usage schema and optional display examples
for its declared models. It replaces, rather than merges with, the plugin's
default `usageSchema` and `usageExamples`. A model may belong to only one
profile, and profile model names must use the spelling declared in `meta.models`.
An empty profile schema is allowed; a missing or null schema is not. Token-unit
profiles require their own examples, using the same validation as the defaults.

The host resolves model aliases before selecting usage metadata. Model-level
pricing and expression-save APIs use the declared target; an ambiguous alias
with multiple targets in the same plugin retains the plugin defaults. Usage
validation uses the executing plugin and final upstream model. Polling
selects metadata from each saved task's model, including in mixed-model batches.
An upstream name that no profile declares, such as a channel mapping to a vendor
endpoint ID, falls back to the client-facing model's profile. Unmatched models
and plugins without profiles retain the plugin defaults.

Profiles do not introduce a request-body whitelist or remove legacy multiplier
extensions. Numeric hook facts retain a consistent floating-point representation
for expression evaluation, including fields outside the selected profile.
Saving an expression checks literal usage keys against the selected schema;
already stored expressions are not migrated. Single-plugin submissions retain
the existing key-check behavior; shared models enforce the compatibility rule
above. Existing runtime error and quota safety checks still apply.
Completion continues to evaluate the frozen expression after overlaying measured
facts; no schema snapshot or database migration is introduced.

This is an optional addition to plugin API version 1. New hosts accept existing
plugins unchanged. Older hosts reject the new metadata field, so upgrade the
host before installing a plugin that declares profiles.

Numeric facts are finite, non-negative values in the declared canonical unit
(`second`, `count`, `token`, or `credit`); enum facts are exact strings from the
declared value list. The schema description is display-only metadata and never
affects evaluation. `token` is the host unit for upstream billing tokens (for
example doubao `usage.completion_tokens`). `credit` is the host unit for vendor
resource-pack units (for example kling `final_unit_deduction`). Both share the
int32 quota bound, not the 3600-second / 128-count limits.

Task usage billing has a deliberately different conversion rule from token
billing:

```
task quota = expression output in USD * QuotaPerUnit * groupRatio
token quota = expression output in $/1M tokens / 1,000,000 * QuotaPerUnit * groupRatio
```

In other words, a task expression already returns the request's dollar cost.
For example, `u("seconds") * 0.4` means $0.40 per second. Engine semantics do
not divide task output by one million.

The visual editor generates, and public pricing displays recognize, exactly
these canonical task shapes. Expressions outside these shapes remain valid in
raw mode but fall back to the special-expression display:

```
# Flat unit pricing
tier("base", u("seconds") * 0.4)

# Enum tiers (conditions may combine enum comparisons with &&)
u("mode") == "pro"
  ? tier("pro", u("seconds") * 0.8)
  : tier("std", u("seconds") * 0.4)

# Optional constant plus multiple numeric usage terms
tier("base", 0.1 + u("seconds") * 0.4 + u("clips") * 0.05)

# Upstream token overlay (doubao Seedance tokens)
# The editor takes a $/1M token input and emits the / 1000000 literal.
# Engine semantics are unchanged: the expression still returns USD.
tier("base", u("tokens") * 9.8 / 1000000)

# Vendor credit overlay (kling resource-pack units)
# The coefficient is the real $/credit price; no /1M scale.
tier("base", u("units") * 0.14)
```

The tier body is an optional non-negative constant plus one or more
`u("<number field>") * <unit price>` terms. Token-unit fields use the
canonical scaled shape `u("<field>") * <dollars per 1M tokens> / 1000000`.
Credit, second, and count fields keep the bare `u("<field>") * <unit price>`
shape. Tier conditions are equality checks
between declared enum fields and values, optionally joined by `&&`, with
chained ternaries following the same ordering rules as token tiers. Numeric
range tiers are not part of the current canonical shape. Request rules after
`|||` remain orthogonal and use the same syntax as token expressions.

Before saving, the host compiles every expression, rejects literal `u()` keys
that the selected task plugin did not declare, and smoke-tests usage vectors.
Every numeric field is exercised at 0, 1, and its host-owned unit ceiling
(`second` 3600, `count` 128, `token`/`credit` int32 max). Enum values are exercised as a
Cartesian product. Smoke vectors are capped at
64, reducing oversized enum dimensions to their first and last values. Every
evaluated result must be finite and non-negative.

Submission evaluates the expression with request-derived usage facts and
freezes both the expression and those facts in the billing snapshot. On
completion, the host overlays completion facts on the frozen submission facts
key by key, so measured values replace estimates while facts omitted by the
completion hook retain their submission values. The same expression is then
evaluated again; a changed fact can therefore produce a settlement delta and a
different matched tier. Evaluation failure keeps the pre-consumed charge.

---

## Architecture

### Data Flow

```
Frontend Editor → Storage → Pre-consume → Settlement → Log Display
```

### 1. Frontend Editor

**File**: `src/features/system-settings`

Two editing modes:
- **Visual mode**: Fill in prices per variable, conditions per tier. Generates expression via `generateExprFromVisualConfig()`.
- **Raw mode**: Edit the expression string directly. Includes preset templates for common models.

The editor outputs a billing expression string and an optional request rule expression string. These are combined via `combineBillingExpr(billingExpr, requestRuleExpr)` before storage.

### 2. Storage

**File**: `setting/billing_setting/tiered_billing.go`

Two option maps stored in the `options` DB table:
- `ModelBillingMode`: `{ "model-name": "tiered_expr" }` — activates tiered billing for a model
- `ModelBillingExpr`: `{ "model-name": "tier(\"base\", p * 2.5 + c * 15)" }` — the expression

On save, the expression is validated:
1. Compiled via `billingexpr.CompileFromCache()` — syntax check
2. Smoke-tested with sample token vectors — ensures non-negative results

### 3. Pre-consume (Quota Estimation)

**File**: `relay/helper/price.go` → `modelPriceHelperTiered()`

When a request arrives and the model uses `tiered_expr` billing:
1. Loads expression from `billing_setting.GetBillingExpr()`
2. Builds `RequestInput` (headers + body) for `param()` / `header()` functions
3. Runs the expression with locally estimated input tokens (`P` and `Len`) and zero output tokens (`C=0`). Client output limits do not affect the reservation. If request token estimation is disabled, the estimated input is zero.
4. Converts output to quota: `rawCost / 1,000,000 * QuotaPerUnit`. For token-priced leaves, multiplies this reservation by `quota_setting.pre_consume_multiplier` (default 1; any finite positive decimal). The multiplier does not change context-length tier selection, actual settlement, or request-priced leaves. The snapshot freezes the multiplier for image quantity retries; group retries reuse the multiplied reservation. Older snapshots with no multiplier retain a factor of 1.
5. Creates `BillingSnapshot` and stores it on `RelayInfo`. Expression and request state stay frozen for settlement. An auto-group retry refreshes group-dependent fields from the selected group before the next upstream attempt. If a free initial group skipped pre-consume and the retry selects a paid group, the billing session is created before that attempt. If an existing session moves to a more expensive group, its reservation is raised to that group's estimate before sending; cheaper groups are refunded only after actual usage is settled.

Wallet trust bypass uses `quota_setting.trust_quota_usd` (default 10 USD; 0 disables bypass). Both the wallet and any limited API token must exceed the threshold. The wallet must still cover the estimated reservation before bypass is considered. Subscriptions and asynchronous tasks do not use this bypass. Legacy token-ratio pricing also reserves estimated input cost times the multiplier, without the former `PreConsumedQuota` floor or output-token estimate. Task usage pricing is unchanged.

### 4. Settlement (Actual Billing)

**Files**: `service/tiered_settle.go`, `pkg/billingexpr/settle.go`

After the upstream response returns with actual token usage:

1. `BuildTieredTokenParams(usage, isClaudeUsageSemantic, usedVars)`:
   - Reads actual token counts from `dto.Usage`
   - For GPT-format APIs (prompt_tokens includes everything): subtracts sub-categories from P/C **only when** the expression uses their variables (detected via AST introspection of the compiled expression)
   - For Claude-format APIs: cache reads and writes omitted from the expression are added to input; separately priced cache remains separate

2. `TryTieredSettle(relayInfo, params)`:
   - Uses the captured `BillingSnapshot`, whose group-dependent fields have been refreshed from the final selected group
   - Re-runs the expression with actual token counts
   - Converts via `quotaConversion()` (version-dispatched)
   - Returns actual quota

### 5. Log Display

**Files**: `service/log_info_generate.go`, `src/features/usage-logs`

Backend: `InjectTieredBillingInfo()` adds `billing_mode`, `expr_b64` (base64 expression), `matched_tier`, and the structured `request_rules` trace list to the log's `other` JSON.

Frontend: Detects `billing_mode === "tiered_expr"`, decodes `expr_b64`, parses tiers via shared `parseTiersFromExpr()`, and renders request multipliers from `request_rules` when present. Without log traces, it falls back to parsing the stored expression.

---

## Key Design Decisions

### Token Normalization via AST Introspection

Different upstream APIs report `prompt_tokens` differently:
- **OpenAI/GPT**: `prompt_tokens` = total (text + cache + image + audio)
- **Claude**: `input_tokens` = text only (cache reported separately)

The system normalizes `p` to mean "tokens not separately priced" by subtracting sub-categories **only when the expression references them**. This is determined by walking the compiled AST to find `IdentifierNode` references — zero runtime cost after first compilation (cached).

Example: `p * 2.5 + c * 15 + cr * 0.25`
- Expression uses `cr` → cache read tokens subtracted from `p`
- Expression doesn't use `img` → image tokens stay in `p`, priced at $2.50

### `len` — Context Length Variable

`len` represents the total input context length, designed for **tier condition evaluation** (e.g. `len <= 200000 ? ...`). Unlike `p`, `len` is never reduced by sub-category exclusion.

**Computation rules:**
- **Non-Claude (GPT/OpenAI format)**: `len = prompt_tokens` (the raw total from the upstream response)
- **Claude format**: `len = input_tokens + cache_read_tokens + cache_creation_tokens` (since Claude's `input_tokens` is text-only, cache must be added back to reflect full context length)

This ensures that heavy cache usage doesn't cause the tier condition to incorrectly evaluate to a lower tier. For example, if a request has 300K total context but 250K is cached, `p` with cache subtracted would be only 50K (standard tier), while `len` correctly reports 300K (long-context tier).

### Quota Conversion

Expression coefficients are $/1M tokens. Conversion to internal quota:

```
quota = exprOutput / 1,000,000 * QuotaPerUnit * groupRatio
```

This matches the per-call billing pattern: `quota = modelPrice * QuotaPerUnit * groupRatio`.

### Expression Versioning

Expressions can carry a version prefix: `v1:tier(...)`. No prefix = v1.

Version controls:
- Compile environment (available variables and functions)
- Token normalization logic
- Quota conversion formula

This enables future evolution without breaking existing expressions.

---

## File Map

| Layer | Files |
|-------|-------|
| Expression engine | `pkg/billingexpr/compile.go`, `run.go`, `settle.go`, `round.go`, `types.go` |
| Storage | `setting/billing_setting/tiered_billing.go` |
| Pre-consume | `relay/helper/price.go`, `relay/helper/billing_expr_request.go` |
| Settlement | `service/tiered_settle.go`, `service/quota.go` |
| Log injection | `service/log_info_generate.go` |
| Frontend editor | `src/features/system-settings` |
| Frontend display | `src/features/usage-logs`, `src/features/pricing` |
| Model detail | `src/features/model-pricing` |
| Log display | `src/features/usage-logs`, `src/features/usage-logs` |
