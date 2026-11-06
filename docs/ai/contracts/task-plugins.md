# Task plugins

## Intended behavior and invariants

PLG-1: The central API v1 Markdown, JSON Schema and TypeScript definitions must agree with
host validation and plugin tests. Read the full central specification before plugin/runtime work.
Native routes and host protocols are different dispatch surfaces; changes require both routing
and billing review. Do not scatter provider documentation into plugins/tasks.
PLG-2: Plugin facts must reflect the effective upstream request, including metadata/passthrough.
Bound seconds/counts, tokens/credits and enums before quota calculation. Host facts are finite,
nonnegative, canonical units; seconds <=3600, count <=128; token/credit saturation uses int32.
Numeric descriptions label billing subject + unit price, with units in unit. Keep wording short,
localized equivalently, without numeric prices/trailing punctuation. Review wording explicitly.
PLG-3: Submission freezes usage/expression; polling overlays measured facts on estimates.
Completion/failure/refund state changes must use guarded transitions; duplicate polls and races
must not double charge/refund. Process-local guards do not prove crash-safe exactly-once accounting.
Profiles replace defaults per model; old hosts reject new profile metadata. Upgrade host first.

Validation: `make lint-plugins`, `make format-plugins-check`, host validation and polling/task
settlement regressions. Contract changes update Markdown/schema/definitions together.
Compatibility applies to persisted tasks as well as new submissions.

## Sources and change procedure

- `tauapi-be/docs/plugin-api/v1.md`
- `tauapi-be/docs/plugin-api/v1.schema.json`
- `tauapi-be/docs/plugin-api/v1.d.ts`
- `tauapi-be/pkg/jsplugin`
- `tauapi-be/service/task_polling.go`
- `tauapi-be/service/task_billing.go`

Review consumers and contract dispositions together; execute selected checks on the actual candidate.
Verification basis: source inspection at e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; no live deployment check.
