# Frontend engineering obligations

Paths in code spans are relative to `tauapi-fe`.

This document defines the development guidelines and best practices for the frontend project, to be followed by both developers and AI assistants. Refer to `package.json` for the authoritative dependencies and scripts.

---

## I. Project Overview

### Tech Stack

| Category            | Technology                                                        |
| ------------------- | ----------------------------------------------------------------- |
| Package manager     | Bun                                                               |
| Framework           | React 19, TypeScript                                              |
| Data and requests   | @tanstack/react-query, axios, Zustand                             |
| Routing             | @tanstack/react-router                                            |
| Tables and lists    | @tanstack/react-table, @tanstack/react-virtual                    |
| Internationalization | i18next, react-i18next, i18next-browser-languagedetector         |
| Dates               | Day.js                                                            |
| UI and styling      | Base UI, Hugeicons, Tailwind CSS, clsx / class-variance-authority |
| Forms               | React Hook Form, Zod                                              |
| Charts              | @visactor/vchart, @visactor/react-vchart                          |
| Tools               | qrcode.react, oxfmt, oxlint, vitest (optional)                    |

Reuse existing project components and capabilities first (see [3.3 Components](#33-components)). If the project has no suitable implementation, evaluate installed dependencies and mature, well-maintained open-source libraries. Implement your own only when reuse, composition, or reasonable extension still cannot meet the requirement, and state the specific capability gap.

---

## II. Table of Contents

- [I. Project Overview](#i-project-overview)
- [II. Table of Contents](#ii-table-of-contents)
- [III. Development Guidelines](#iii-development-guidelines)
  - [3.1 Internationalization](#31-internationalization)
  - [3.2 Code Style and Types](#32-code-style-and-types)
  - [3.3 Components](#33-components)
  - [3.4 Performance](#34-performance)
  - [3.5 State Management](#35-state-management)
  - [3.6 API Requests](#36-api-requests)
  - [3.7 Forms](#37-forms)
  - [3.8 Routing](#38-routing)
  - [3.9 Error Handling](#39-error-handling)
  - [3.10 Styling](#310-styling)
  - [3.11 File Organization](#311-file-organization)
  - [3.12 Accessibility](#312-accessibility)
  - [3.13 Security](#313-security)
  - [3.14 Testing](#314-testing)
  - [3.15 Dependency Management](#315-dependency-management)
  - [3.16 Build and Deployment](#316-build-and-deployment)
- [IV. Collaboration and Commits](#iv-collaboration-and-commits)

---

## III. Development Guidelines

### 3.1 Internationalization

- **Page text**: All user-facing copy MUST support i18n; translate it with `t()` from `useTranslation()`.
- **Usage scenarios**
  - **React components**: MUST use `const { t } = useTranslation()` so the component re-renders when the language changes.
  - **Non-React contexts** (utility functions, constants, class methods): MAY use `import { t } from 'i18next'`. Such usage does not update automatically on language change; use it only where reactive updates are not required.
  - Even if a parent component already uses `useTranslation()`, child components SHOULD still use it themselves to remain independent.
- **Proper nouns**: Brands, products, and technical terms MAY remain in English (e.g. API, React, TypeScript). If an established translation exists, use the translation.
- **Translation keys**: Use flat English source strings as keys, consistent with the existing locale files.

- **Enums and copy (i18n in constants)**
  Each feature's `constants.ts` often contains "enum/status + display copy" or "success/error messages". Follow these conventions uniformly to avoid missing i18n or inconsistent usage:
  - **Success/error/notice messages** (e.g. `SUCCESS_MESSAGES`, `ERROR_MESSAGES`): the constant value represents only an **i18n key** (the same literal as the English fallback). When displaying, you **MUST** go through `t()`, e.g. `toast.success(t(SUCCESS_MESSAGES.API_KEY_CREATED))`, `toast.error(t(ERROR_MESSAGES.UNEXPECTED))`. It is **forbidden** to use `toast.success(SUCCESS_MESSAGES.xxx)` directly as the final copy.
  - **Labels of statuses/options**: in constants, use **labelKey** (a string, i.e. an i18n key) consistently, and render it in components with `t(config.labelKey)`; alternatively, by convention, use `label` to store a key string identical to the English text and render it with `t(config.label)`. Use only one approach within the same feature; do not mix them.
  - **When adding such constants**: register the corresponding key in `src/i18n/static-keys.ts` (if the project uses it for extraction), or ensure the copy appears as a `t('...')` literal so it can be scanned, to avoid missing translations.

**Number formatting and Intl locale parameters (mandatory)**

- For plain and compact number display, you MUST reuse `formatNumber` / `formatCompactNumber` from `@/lib/format` first. For amounts, balances, and quotas, use the existing `@/lib/currency` or the corresponding business wrapper, preserving precision, units, and conversion semantics. Use `Intl.NumberFormat` directly only for format options the existing wrappers cannot express; do not change the displayed numeric precision just to unify the calling style.
- `zhCN` / `zhTW` are the project's UI language codes, not valid BCP 47 tags. Any argument derived from the UI language, whether referenced directly, destructured, aliased through a variable, or passed through functions, MUST be converted with `toIntlLocale()` from `@/i18n/languages` before it enters `Intl.*`, `toLocaleString` / `toLocaleDateString` / `toLocaleTimeString`, or a shared formatting function. Do NOT write your own mapping for language codes such as `zhCN`; handling only Simplified Chinese would miss Traditional Chinese.
- React components subscribe to the language via `useTranslation()` and compute `const locale = toIntlLocale(i18n.resolvedLanguage || i18n.language)` at render time, e.g. `formatNumber(value, locale)`. Do not freeze the current language in a module constant or initial state; the format MUST update after a language switch. Where the runtime default locale or a fixed protocol locale is explicitly intended, you MAY omit the locale, pass `undefined`, or use a valid fixed tag.
- `bun run lint` / `bun run lint:fix` enable the **`project/intl-locale` error**, which checks raw `language` / `resolvedLanguage` in the calls above, local variable assignments and destructuring aliases, and invalid fixed tags. Do not bypass it with lint-disable. The static check does not track data flow across functions or modules, so callers must still follow the conversion convention.
- When changing language conversion or number formatting, regression tests MUST cover `zhCN`, `zhTW`, the other five UI languages, and the fallback for invalid languages; when component language responsiveness is involved, they MUST also cover switching languages. When changing the lint rule, verify that violating code is reported and valid conversions produce no false positives; passing type checks and builds does not replace these verifications.

### 3.2 Code Style and Types

- **Expressions**: Nested ternary expressions of 2 or more levels are forbidden; use `if-else`, early returns, or extracted functions instead. A single-level ternary MAY be kept, but it must be concise.
- **Readability**: Control function cyclomatic complexity and split complex logic into small functions; give variables and functions meaningful names that follow conventional rules such as camelCase.
- **TypeScript**: Avoid `any`; prefer concrete types or `unknown`. Explicitly annotate parameter and return types. Use `import type { X } from '...'` for type-only imports.
- **Type checking**: After every change to TypeScript or TSX code, run the type check (e.g. `bun check -b`). If type errors appear, you MUST fix them until there are none; do not leave any behind.
- **Lint checking**: Before finishing any code change, you MUST run lint on the files involved and fix all lint errors in those files; do not leave any errors behind. Warnings MAY be handled according to the scope and risk of the change.
- **Destructuring**: Do not destructure objects unless necessary, especially component props; using `props.xxx` directly is clearer and avoids adding needless code complexity.

### 3.3 Components

**Search first, then reuse, and only then add new (mandatory)**

- **Search before development**: Before adding or modifying UI, you MUST read the project `shadcn-ui` skill and use `rg --files` / `rg` to search `src/components/` and the relevant `src/features/`; when generic interactions are involved, also check `src/hooks/`. Search by purpose and behavior, not only by the name of the component you plan to add. Read the candidate component's implementation, props, and actual usage examples before settling on an approach.
- **Reuse order**: Prefer project business wrappers that fit the scenario; if their capability is insufficient, first evaluate existing props, slots, composition, or a compatible extension. Only when business wrappers are truly unsuitable, compose from the existing base components in `src/components/ui/`. Only when a capability gap remains within the project, evaluate introducing a component or adding a new implementation; checking external registries does not replace searching within the project.
- **Reuse down to the behavior layer**: Using only base components such as `Button`, `Dialog`, and `AlertDialog` does not mean the corresponding generic capabilities such as copy, confirmation, and dialog layout have been reused. When an existing business wrapper can cover the case, you MUST use that wrapper; it is forbidden to reassemble the same interaction, state, and styling inside a feature.
- **Conditions for adding new**: Before adding a replacement implementation, you MUST state the specific capability the candidate component lacks, and record the candidate paths and the reasons they cannot be reused, composed, or compatibly extended in the change description or PR. Differences in copy, icons, size, color, or host page are not grounds for a duplicate implementation; handle those differences through existing APIs and theme conventions first.
- **Reasonable composition**: New feature components that carry business data, permissions, events, and content are allowed, but the generic UI and interactions within them MUST still be reused. Extending a shared component MUST preserve existing call behavior; do not stuff unrelated business logic into it for a single page, and do not build an over-generalized abstraction just to remove a small amount of similar code.
- **Base element boundary**: In business code, controls already covered by base components, such as buttons, inputs, selectors, and overlays, MUST use the project components; do not hand-write equivalent controls or bypass the wrappers to call the underlying library directly. Plain semantic layout, hidden fields, and special controls that existing components cannot express MAY use native elements; special controls must still state the capability gap and meet accessibility requirements.

The following are common search entry points; do not treat this table as a complete component inventory:

| Scenario                                    | Project entry point to check first                                                   |
| ------------------------------------------- | ------------------------------------------------------------------------------------ |
| Generic dialog layout                       | `@/components/dialog`                                                                |
| Delete, dangerous, and ordinary confirmations | `@/components/confirm-dialog`                                                      |
| Copy button and clipboard interaction       | `@/components/copy-button`, `@/hooks/use-copy-to-clipboard`                          |
| Empty, loading, and error states            | `@/components/empty-state`, `@/components/loading-state`, `@/components/error-state` |
| Tables, pagination, toolbars, and list layout | `@/components/data-table`; read that directory's `README.md` and public exports first |
| Base controls: buttons, inputs, selects, tooltips | `@/components/ui/`; `components.json` and the local implementation are authoritative |

- Use function components and Hooks with a single responsibility; component props MUST have explicit types (interface or type alias).
- **Props usage**: Do not destructure component props unless necessary; access properties via `props.xxx` to keep code clear (see [3.2 Code Style and Types](#32-code-style-and-types)).
- When a single file exceeds about 200 lines, consider splitting out child components or extracting logic into custom Hooks; type definitions MAY live in the same file as the component or in the same module's `types`.

### 3.4 Performance

- **React**: Use `useMemo` and `useCallback` judiciously to reduce unnecessary re-renders; avoid creating new objects/arrays on the render path; use `React.memo` where necessary.
- **Code splitting**: Use `React.lazy` and dynamic `import` for on-demand loading to control first-screen and route bundle size.
- **Assets**: Choose appropriate image formats and sizes; consider virtual scrolling for large lists (e.g. @tanstack/react-virtual) and lazy loading for large numbers of images.

### 3.5 State Management

- Define stores with Zustand's `create`, and give state and actions clear types.
- In components, prefer subscribing with selectors to avoid whole-store subscriptions that cause extra renders, e.g. `const user = useAuthStore((s) => s.auth.user)`.
- For state that needs persistence, read/write localStorage inside the store and restore it at initialization.
- Place stores by feature in `src/stores/`; keep each file's responsibility clear and names descriptive.

### 3.6 API Requests

- **React Query**: Use `useQuery` for data fetching and `useMutation` for changes; configure a unique `queryKey` for every query (array form with a consistent hierarchy is recommended); call `invalidateQueries` for related queries in `onSuccess`, optionally combined with optimistic updates. Handle server errors uniformly through `handleServerError` (see [3.9 Error Handling](#39-error-handling)).
- **Axios**: Use the project's shared `api` instance (including `baseURL`, `headers`, `withCredentials: true`); GET requests are deduplicated by default and special requests can disable this via configuration; authentication refresh and request retry are handled in interceptors; ordinary error notifications are the responsibility of the final failure callback of the Query/Mutation or of the direct caller.

### 3.7 Forms

- Use React Hook Form + Zod: define the schema under the feature module's `lib/`, export the form type with `z.infer`, and use `useForm` with `@hookform/resolvers/zod` for validation.
- Put submit logic in `onSubmit` and show loading and error states; after success, reset the form or close the dialog depending on the scenario. Map server validation errors to the corresponding fields and display them (see [3.9 Error Handling](#39-error-handling) for how to display field-level errors).

### 3.8 Routing

- Use TanStack Router; route files are located in `src/routes/` and defined with `createFileRoute`; validate search parameters with a Zod schema + `validateSearch`.
- Perform authentication and redirects in `beforeLoad` to avoid unnecessary requests; for nested structures use layout routes and prefixes such as `_authenticated`, and render child routes via `<Outlet />`.
- Navigate with `useNavigate` or `Link`, keeping type safety, and avoid manipulating `window.location` directly.

### 3.9 Error Handling

- **Server errors**: Use `handleServerError(error, fallbackMessage?)` uniformly, and preferentially preserve the specific reason from the server. When the same failure propagates along `cause`, notify only once; different operations are notified separately even if the text is identical. It is forbidden to write a full Axios error object (which may contain credentials) directly to the console.
- **Notification ownership**: The ordinary request interceptor does not show a Toast. Use the shared `createAppQueryClient` to notify when a Query/Mutation finally fails; a Mutation's custom `onError` is responsible for its own notification or form errors. Do not report errors during automatic retries or on deliberate cancellation. `meta.errorToast: false` disables the automatic notification, and the page can still call the error handling function explicitly.
- **Business failures**: Preserve the original API response contract; a Query uses `requireServerSuccess` to check `success: false`, or the business layer throws with `createServerError(response, fallbackMessage?)` while preserving the source. Direct requests MUST explicitly handle failure responses and Promise rejections; a Mutation that needs to display a failure state MUST NOT treat a failed result as a successful save.
- **Authentication compatibility**: Preserve the stable error code mapping and the safe messages of `AuthOperationError`; do not unwrap its source to display masked details. Maintain the existing constraints on refresh, redirect, and no replay of one-time authorization.
- **Display**: Use a uniform approach such as `toast.error`; route-level errors are handled by `errorComponent`, providing a friendly error page and recording information useful for troubleshooting.
- **Forms**: After validation and server errors are mapped to fields, display them below the field; use approaches consistent with the form library such as `form.setError`.

### 3.10 Styling

- Primarily use Tailwind utility classes, and merge dynamic class names with `cn()`; avoid inline styles in non-dynamic cases.
- For responsiveness, use mobile-first and Tailwind breakpoints (`sm:`, `md:`, `lg:`, etc.); use CSS variables and `dark:` for theming and dark mode, centralize custom styles in `src/styles/`, and write as little custom CSS inside components as possible.

### 3.11 File Organization

- **Feature modules**: Place them in `src/features/<feature>/`, containing `components/`, `lib/`, `hooks/`, and, as needed, `api.ts`, `types.ts`, `constants.ts`, entry components, etc.
- **Shared**: Put shared components in `src/components/` and shared utilities and types in `src/lib/`; component files use PascalCase, utility/type files use kebab-case or `types.ts`, and types are named in PascalCase and exported with `export type`.

### 3.12 Accessibility

- Use semantic HTML (e.g. `header`, `nav`, `main`, `footer`), and associate inputs with `label` in forms.
- Ensure keyboard operability and a sensible focus order; use ARIA where necessary (e.g. `aria-label`, `aria-expanded`, `aria-hidden`); add `aria-hidden="true"` to decorative icons, and provide text equivalents for important information.
- Contrast MUST meet WCAG 2.1 AA (at least 4.5:1 for body text).

### 3.13 Security

- Validate authentication and permissions at the route and API layers; add secondary confirmation and similar safeguards for sensitive operations.
- Validate data on both frontend and backend (e.g. Zod), and do not trust frontend-only validation; do not store sensitive information in frontend storage, use environment variables for configuration, and never hard-code secrets.
- Rely on React's default escaping and use `dangerouslySetInnerHTML` with caution; for cross-origin requests and cookies use `withCredentials` and handle CSRF as the backend requires.

### 3.14 Testing

- Prefer unit tests (Vitest) for utility functions and pure logic, with test files named `*.test.ts`; test components with React Testing Library for interaction and behavior, and avoid testing implementation details.
- When adding features, fixing defects, or changing existing behavior, you MUST add or update tests accordingly; a bug fix MUST first write a failing test case that reliably reproduces the problem, then implement the fix and confirm the case turns green.
- When changing the layout, size, scroll positioning, focus management, keyboard operation, selected state, disabled state, loading state, empty state, error state, or responsive behavior of a frontend component, you MUST add corresponding regression tests covering the user-visible behavior protected by this change, to prevent later adjustments from reintroducing the problem.
- Tests for a feature module or component module MUST be placed in that module's dedicated `__tests__/` directory, e.g. `src/components/model-group-selector/__tests__/layout.test.ts`; it is forbidden to put new test files flat in the same directory as production code files.
- Name test files after the responsibility under test, e.g. `layout.test.ts`, `selection.test.ts`, `validation.test.ts`; one test file covers exactly one clear module or responsibility, avoiding oversized cross-module test files.
- Each test case SHOULD protect exactly one describable behavior, and its name MUST include the trigger condition and the expected result; prefer a clear Arrange, Act, Assert structure, and avoid mixing multiple unrelated assertions in a single case.
- Tests MUST cover the main success path as well as the key boundaries and failure paths involved in this change, including empty data, single and multiple items, overlong text, invalid input, disabled state, async failure, and fallback logic; do not mechanically enumerate unrelated inputs just to increase the count.
- Layout tests SHOULD assert explicit and stable behavior contracts, such as fixed size, arrangement direction, overflow strategy, scroll target, and fallback path; do not merely assert that the component renders, and do not rely on browser pixel tolerances, browser-private implementations, or brittle full-class-string snapshots.
- Component interaction tests SHOULD query elements from the user's perspective and perform click, input, keyboard, and focus operations, asserting visible results, accessible states, or outward callbacks; it is forbidden to directly assert internal component state, call counts of private functions, or DOM hierarchy that has no user meaning.
- Components involving accessibility MUST cover the accessible name, keyboard operability, and attributes consistent with the visual state such as `aria-expanded`, `aria-selected`, `aria-disabled`, and `aria-invalid`.
- Tests involving i18n copy SHOULD locate elements through stable roles, labels, or translation key semantics, and avoid using the full display text of one language as a brittle assertion unrelated to the business; if the translated content itself is the contract, explicitly cover language switching or fallback behavior.
- Async tests MUST wait for an explicit UI state or Promise result; do not use a fixed `sleep`, rely on execution time, or create races; mock timers, network requests, and browser APIs in a controlled way only at necessary boundaries, and restore them after each case.
- Prefer testing real code paths; only uncontrollable boundaries such as external network, time, randomness, storage, or browser APIs MAY be mocked. It is forbidden to mock the module under test itself, and do not compute expected results by copying production logic into the test.
- Test data SHOULD use minimal, explicit fixtures with business meaning; each test MUST independently initialize and clean up global state, caches, localStorage, mocks, and timers, so that cases can run alone and do not depend on execution order.
- Snapshot tests apply only to stable, human-reviewable structural output; interactive components, complex DOM, and Tailwind class lists MUST NOT use broad snapshots in place of behavior assertions.
- Supplement key flows with integration and E2E tests (e.g. MSW to simulate APIs, Playwright/Cypress); target coverage of 80% or more for core features, focusing on business paths and key branches.
- Tests MUST protect real user behavior, stable API contracts, or explicit regression paths; it is forbidden to add smoke, sleep/timing, random-input, log-output, or merely code-runs tests for the sake of coverage.
- When adding or substantially rewriting tests, prefer the standard assertions and queries of Vitest and React Testing Library, and avoid hand-written generic assertion helpers; extract test helpers only to express project-specific business invariants.
- When cleaning up tests, first merge duplicate scenarios and delete assertions on unclear implementation details; if an old test indirectly covered a real contract, replace it with a smaller, more direct behavior test.
- Before committing, you MUST run at least the affected test files, and, depending on the scope of impact, run the relevant test suites, `bun check -b`, and lint on the files involved; do not declare testing complete without seeing the latest passing results.

### 3.15 Dependency Management

- Use **Bun**: `bun install`, `bun add <pkg>`, `bun add -d <pkg>`, `bun remove <pkg>`, `bun pm ls`, `bun update`, etc.
- Before adding a dependency, evaluate its maintenance status, size, and license; keep production and development dependencies clearly separated, control versions with `^`/`~`, and update regularly to pick up security fixes.

### 3.16 Build and Deployment

- Use Rsbuild; see `rsbuild.config.ts` for configuration; scripts are as defined in `package.json` (e.g. `bun run dev`, `bun run build`, `bun check -b`, `bun run lint`, `bun run format`); for package management see [3.15 Dependency Management](#315-dependency-management).
- For code splitting and lazy loading strategy see [3.4 Performance](#34-performance); use appropriate formats and compression for assets; use `.env` for environment variables with the `VITE_` prefix, and do not hard-code them in code.
- **Before release**: run typecheck, lint, and format checks, complete the production build, and check the artifact size and environment variable configuration.

---

## IV. Collaboration and Commits

- Commit messages must be clear and follow project conventions, describing what changed and why; keep the language (Chinese or English) consistent.
- Changes must pass code review, comply with this document, and be checked for quality, performance, and security.
- Before completing a UI change, you MUST check whether newly added components, base component imports, and hand-written interactions bypass existing business wrappers; if a duplicate implementation is found, convert it to reuse within the scope of this change. A new implementation that is retained must have its capability gap explained in the change description; passing typecheck, lint, and tests does not replace this check.
- When making major feature or guideline changes, update the relevant documentation and `AGENTS.md`.

---
