# Frontend billing expression behavior

The backend pkg/billingexpr is actual charging authority. Browser simulation changes no
configuration, sends no requests and charges nothing. Executability, structured display
and lossless visual editability are independent capabilities: max(p*2,100) may execute but
cannot be extracted as an input unit price of 2. Never replace unknown request context
with {}, zero, false or a default tier.

## Compilation and evaluation

compileBillingExpression returns ready with source/AST/dependencies/rule locations or diagnostics.
evaluateBillingExpression returns success with cost/matchedTier/requestRules, or invalid,
unsupported or missing_context. Cache up to128 compiled raw strings; each evaluation has
fresh state so tier/time/rule hits cannot leak. No eval/new Function/global/member execution.
structure.ts splits top-level structures without interpreting string escapes as operators.
Compatibility entry points billing-expr/tier-expr/task-expr preserve field names/order/units/fallbacks.

BillingSimulationContext supplies normalized tokens, optional request body/headers, explicit task
usage, and one absolute now for the entire evaluation. Do not subtract caches twice or infer
usage/tokens from request JSON. Basic len defaults p+cr+cc+cc1h+cc12h with explicit override.
When cc is priced but long TTL variables are not, fold cc1h at6/3.75 and cc12h at2 into cc;
without cc pricing those writes are not charged by that basic estimate.
Missing request means no request simulation; explicit {} means known empty request.
UI supplies empty request only after enabling simulation. Missing task fact yields nil;
missing whole usage context gives missing_context. Input tokens must be finite/nonnegative;
failed execution has no usable cost and must not become zero.

Support default/v1 syntax, decimals/scientific numbers, quoted escaped strings, booleans/nil,
parentheses, arithmetic/comparison, boolean short circuit and ternaries. Conditions are boolean,
not JS truthiness; no JS string/number coercion. Modulo requires integer operands while JSON
and token numbers follow backend floating semantics. Functions include tier/param/header/has/u,
hour/minute/weekday/month/day, min/max/abs/ceil/floor. Advanced Expr/GJSON queries, pipes,
wildcards, arbitrary functions/objects report unsupported without destroying source. Bound length,
token count and depth. Do not claim Go equivalence beyond JavaScript safe-integer precision.
param trims paths and supports dotted/indexed/escaped keys and items.# length; absent/null ->nil,
explicit zero/false/empty string preserved. Header names are case-insensitive, trim names/values,
skip empty entries and return empty string for missing. has distinguishes nil/empty substrings
and uses backend fmt.Sprint container representation.
Time functions use expression IANA timezone; empty/invalid existing timezone falls back UTC,
Local is unsupported because it depends on server process timezone. Hour0..23, minute0..59,
Sunday0, month1..12. Rule traces require request/time probes and literal branches with fallback1;
short-circuited rules remain unmatched.

## Display contracts and units

Raw evaluator returns expression output without currency/group/topup conversion. Token display
converts per-request cost by dividing by1M exactly once; task output is already per request USD,
including any explicit token-field /1M inside the expression. Existing currency/topup/group
formatting remains; browser simulation does not implement quota rounding/saturation.
Display recognizes whole standard token tiers, schema-supported task enum tiers, and outer time
branches containing standard token tiers. Undeclared task enum values are unreachable and skipped;
task-display treats those comparisons as false. Unknown request conditions never become ranges.

| Consumer | Required behavior |
| --- | --- |
| Square cards/list/cache prices | Lowest available group without selection; selected group otherwise; zero ratio valid |
| Token summary | First tier and existing order; never cheapest tier/range across tiers |
| Request multipliers | Separate base and additional rules including independent time factors |
| Task summary | Last tier base; existing per-field ranges; free tiers included; equal prices omit range |
| Detail base | Ratio1 |
| Detail/group tables | All tiers/conditions/groups, not current-time summary |
| Task matrix/examples | Preserve matrix, unique complement and selection; public examples exclude request factors |
| Logs | Backend tier/traces first; label first with usage fact assistance; never guess price for unknown label |
| Visual/snapshot/sync | Lossless conversion, raw text and fallback preserved |
| Special/unconfigured | Preserve special/empty state; no partial price extraction |

getDynamicPricingTiers/parseTiersFromExpr return full tiers. getCurrentTimePricingTiers is for
live summary only: select current outer time branch then first tier even if more expensive.
condition-display derives localized weekday/hour/combinations/complements from AST and falls
back to raw condition only when unrecognized. Preserve raw timezone names in detail/log text.
usePricingTime shares a minute clock, updates at minute boundaries/visibility changes and does
not subscribe without time dependencies. Logs never subscribe to the live clock.

## Lossless editor

parseVisualBillingDocument builds condition branches and price leaves. Serialize returns complete
source or field errors, never partial expressions. Preserve source, node identity/spans, variable
presence and string drafts; compare to origin nodes and replace only changed spans.
Basic estimate excludes request and group multipliers. Separate request simulation includes request
rules but excludes groups. Use JsonCodeEditor body and JsonEditor string-map headers; require ISO
date-time with offset for supplied time. Invalid JSON/time invalidates result. Boolean usage uses
schema controls preserving true/false, without changing old matrix recognition.
Request context stays UI-local; preview/time ticks never call configuration update callbacks.
Never replace an uneditable raw expression with default visual prices.

Prefer original tier form; use condition-tree document when it cannot represent the source.
Preserve tryParseVisualConfig meaning and price-sync consumers. Explicit zero cache price needs
document mode even for a single tier because old form omits zero extras. Condition tree supports
bounded nested &&/||/!, five time functions and p/c/len comparisons with finite nonnegative numbers;
time values are integers. Nested branches may contain token tiers; else is exact complement.
Price leaves are standard tier(name, variable*price+...) or fixed(amount), mixed in one tree.
Each token variable occurs once; order and single terms are supported. Range controls preserve
strict/inclusive endpoints, midnight uses OR and hours permit <24. Escape tier names. Missing
variables differ from explicit cr*0. Currency converts price fields only, not times/thresholds/factors.

Unedited mode/currency switch, simulation and save preserve raw source. Structural changes rebuild
only affected subtree and preserve parentheses; other edits replace corresponding spans. Additional
request-rule source regenerates only after its own edits; time pricing does not become request factors.
New branches copy current prices to both sides with empty condition. Switching token/request retains
the other local price draft. New fixed price stays empty and blocks save; explicit0 is free, storage USD.
Fixed prices never scale with1K/1M display. Mixed units are labelled. Log highlights match tier name
plus billing_unit/fixed_price, prioritizing backend records. Empty groups, invalid numbers/new IANA
zones or compile errors block save/mode switch and retain last valid config. Preserve old timezone
identifiers and backend fallback while requiring new valid IANA identifiers.
Use existing controls; AND/OR/NOT groups use subtle blue/purple/amber, group numbers and connectors.
Keep compact rows; coalescing paired ranges changes display only, never rewrites unedited AST groups.
Put extra actions in menus and label true/else targets. Nonlinear/min/max/repeated-variable/request
conditions outside editable shapes retain source; calculation/display never implies editability.

## Regression requirements and provenance

Read backend fixture as canonical, frontend copy as synchronized local snapshot; UPSTREAM hashes
remain import provenance. conversion cases bind backend inputs and displayTiers assert branches/prices.
Preserve finite equivalent AST variations: parentheses, max argument order, factor order and audio OR.
Use fixed absolute times for peak boundaries, weekends, midnight/month changes and DST. Preserve existing
price/group/task/log/editor/sync expectations. Component cases cover explicit simulation enable, JSON/time
errors, factors, units, unchanged configuration and card time updates. Avoid whole-DOM snapshots,
network services or the browser's real current time as expected calculations.
Original Chinese source remains unchanged as upstream-owned provenance at
src/features/pricing/lib/billing-expression/README.md. Source review only; semantic tests are separate.
