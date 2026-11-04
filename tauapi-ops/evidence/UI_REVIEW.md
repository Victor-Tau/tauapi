# Minimalist Flat — UI review summary (fe-r3-0dab41b, 2026-11-04)

Design source: GOAL.md §9. Implementation rules: `docs/MINIMALIST_FLAT.md`. Full matrix: `UI_INVENTORY.csv` (77 rows: every route file, every `$section` from the 11 section registries, error/auth/setup states). Screenshots are git-ignored under `evidence/raw/` (isolated QA data only: QA admin, `qauser`, mock channel, no real keys or payment data).

## What changed (tauapi-fe commits 3097ff7, 0dab41b)

- **Tokens** (`src/styles/theme.css`): page #FAFAFA/#111111, surface #FFFFFF/#1B1B1B, muted #F5F5F5/#262626, text #171717/#F5F5F5, secondary #525252/#A3A3A3, divider #E5E5E5/#333333, input border #737373, primary #1D4ED8/#93C5FD, primary-fg #FFFFFF/#111827, focus #2563EB/#93C5FD. Base radius 6px; radius steps above 8px capped.
- **Presets** keep their accent colours; surfaces stay neutral for all presets; radius preference bounded to 0–8px; font, density and layout preferences kept, localStorage untouched.
- **Primitives** (`src/components/ui/*`): solid scrims (no backdrop blur), no decorative popover shadows, hairline `border` rings, solid 2px focus ring, 36px controls / 44px on coarse pointers, 48px table rows, no press-scale.
- **Global CSS / motion**: no card hover lift, no row entrance stagger, glass utilities solid, entrance animations reduced to ≤200 ms opacity fades; `prefers-reduced-motion` honoured.
- **Features**: 170+ files across home, pricing, rankings, auth, setup, errors, legal, dashboard, usage logs, keys, playground, wallet, profile, security, channels, models, users, subscriptions, task plugins, system info, system settings, ai-elements, data-table. Decorative gradients, glows, glass, shadows, hover scaling and oversized display type removed; decorative raw colours moved to semantic tokens.
- **Kept on purpose**: status-scale colours asserted by tests (success-rate strip, key quota), chart palettes, brand and provider logos, loading/streaming indicators, avatar/dot/switch round shapes, New API / QuantumNous branding, copyright headers and links (verified: 0 headers lost).
- **Added**: accessible name on the mobile nav trigger; a non-forcing new-release notice.

## Verification

| Check | Result |
| --- | --- |
| Typecheck / unit tests | pass / 202 files, 2465 tests pass (same count as upstream baseline) |
| Lint | changed files: same error set as upstream versions of those files (upstream baseline has 152 lint errors, identical list) |
| Page matrix (QA) | 230 of 231 page × viewport/theme captures reached the intended page with its marker visible; no page-level horizontal overflow. Exceptions: `oauth-cb` mobile redirects to `/sign-in` before capture (expected for an invalid code; desktop captures show the waiting state), and model-pricing mobile renders with its title scrolled under the tab bar |
| Overlays / menus / drawers (QA) | dialog, command palette, profile menu, theme drawer, channel drawer, select popover, charts (canvas), mobile sidebar sheet, mobile public menu — light and dark: 17/17 rendered |
| Setup wizard | steps 1–4 in light/dark desktop and light mobile against a real uninitialised throwaway backend; completes and lands on `/` |
| Contrast | `evidence/ui/CONTRAST.md`: 16/16 required pairs pass (text ≥ 4.5:1, controls/focus ≥ 3:1) |
| Keyboard | sign-in tab order username → password → show-password → forgot → submit, each with a visible focus ring and `<label>`; Enter submits and shows field errors; dialog opens from keyboard, focus moves inside, Escape closes and focus returns to the trigger; Ctrl+K opens the command palette; no unnamed header/sidebar icon buttons after the fix |
| zh @ 200% zoom | 7 representative pages at 720×450 CSS px, devicePixelRatio 2: no horizontal overflow |
| Permissions | common user: /channels, /users, /system-settings/*, /task-plugins → /403; admin menu hidden; `/api/channel/` → 401 |
| Playground | streamed reply from the mock model, Stop ended it after 2 of 20 chunks, error model shows the error |

## Screenshots actually opened and inspected

home (light/dark desktop), pricing (light desktop), sign-in (dark mobile), keys (light mobile), playground (dark mobile, stopped stream), dashboard overview (light desktop), dashboard models charts (light), channels (dark desktop), create-channel drawer (light, fe-r2 and fe-r3), users (light mobile), usage logs (dark desktop), security (light desktop), system settings › operations › behavior (dark desktop), billing › model pricing (light mobile), error 500 (light), API key dialog (dark), theme drawer (light), command palette (dark), mobile sidebar sheet (dark), setup wizard steps 2–3 (light/dark), zh 200% channels.

Issues found during review and fixed: channel picker search box still used the old translucent input fill (fixed in fe-r3, input-token fills across command/combobox/tabs/input-group/json editor); theme drawer radius labels showed the old rem values (fixed); mobile nav trigger had no accessible name (fixed).

## Not first-party / not restyled

OAuth provider sites, payment provider pages, third-party iframes and user-supplied HTML/Markdown content. Their entry points, containers, loading and error states are first-party and are covered above. SMTP/OAuth/payment flows are not configured in production (see HANDOFF.md).
