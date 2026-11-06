# Shared UI, theme, i18n and accessibility

## Responsibility and boundaries

This domain owns the shared ui, theme, i18n and accessibility maintenance surface in `tauapi-fe`.
Follow source entry points below; cross-component behavior belongs to linked contracts.
Library conversion excludes host transport/billing; frontend UI excludes server authorization;
operations procedures exclude unapproved production mutations.

## Source entry points and flow

- `tauapi-fe/src/components`
- `tauapi-fe/src/styles`
- `tauapi-fe/src/i18n`

Feature -> existing business wrapper -> UI primitive -> semantic theme tokens -> i18next -> Intl locale conversion and keyboard/accessibility state.

## Consumed and provided contracts

Follow the component engineering obligations for UI reuse, accessibility and localization.

## Validation and failure localization

Selected checks: frontend-typecheck, frontend-tests, frontend-lint. See registry for literal runners and prerequisites.
Inspect shared Dialog/ConfirmDialog/CopyButton/data-table before replacing behavior. Verify language switching, zhCN/zhTW conversion, precision, focus and accessible names; lint does not replace manual capability-gap review.
Source inspection is the verification basis at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; runtime checks are separate.

## Update triggers

Update this card when entry points, flow boundaries or validation commands change.
Review contracts when behavior, compatibility or failure handling changes. Re-route against
actual diff; source-only refactors may use evidence-backed reviewed_unchanged dispositions.
