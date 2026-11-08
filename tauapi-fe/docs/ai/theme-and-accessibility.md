# Key Yi (Auntie Key) — implementation rules for tauapi-fe

Current design intent: the Key Yi street-stall brand style — warm low-saturation palette,
chestnut outlines, hard offset "sticker" shadows, pill controls and rounded display type.
Source paths below are relative to tauapi-fe. Review actual tokens before changing values:
- `src/styles/theme.css`: light tokens bg #FAF6F0, card/popover #FFFFFF, fg #433534,
  muted #F3ECE2, muted-fg #735F5A, accent #FFEBD9, border #E6DACB (hairlines),
  input/outline #433534, primary #FF9E4A with primary-fg #433534, ring #FF9E4A,
  success #2E7A58, destructive #C93C3C, warning #A35A00, info #3B6EA5. Brand accents
  `--brand-mint`, `--brand-mint-soft`, `--brand-mint-ink`, `--brand-strawberry` and
  `--brand-butter` carry the palette pastels for fills. Dark tokens use a chestnut canvas
  (#221A19, card #2D2423) with primary #FFA65A, outline #7D6763 and shadow #0F0B0A.
- `--primary` is the brand fill. `--text-color-primary` maps `text-primary` to
  `--primary-ink` (#A3500C light) because #FF9E4A text fails AA; named presets reset
  `--primary-ink` to their own `--primary`.
- Utilities from `@theme inline`: `border-outline`/`ring-outline`, `shadow-sticker-sm`
  (2px), `shadow-sticker` (4px), `shadow-sticker-lg` (6px), `ease-bounce`
  (cubic-bezier(0.175, 0.885, 0.32, 1.275)) and `font-brand`.
- Radius: `--radius` 12px; `rounded-xl` 16px (cards, menus), `rounded-2xl` 24px (dialogs,
  sidebar inset, feature panels). Buttons, inputs, select triggers, tabs and badges use
  `rounded-full`; textarea and multi-line input groups use `rounded-xl`.
- `src/styles/index.css`: `KeyYi Rounded` @font-face (renamed OFL subset in
  `src/assets/fonts/`, license in `public/fonts/KeyYi-Rounded-OFL.txt`) applies to h1–h3
  and card/dialog/sheet/drawer title slots unless the serif font axis is selected. Body,
  tables and code keep the UI sans and monospace fonts. `.keyyi-awning`, `.keyyi-float`,
  `.keyyi-pulse`, `.keyyi-sparkle` and `.keyyi-key-swing` animate only under
  `prefers-reduced-motion: no-preference`. glass-* = solid card + 2px outline.
- `src/components/ui/*`: default/outline buttons have 2px outlines, sticker shadows, a
  -2px hover lift and press-down feedback, disabled by `motion-reduce`. Cards use 2px outline
  + `shadow-sticker`; dialogs `ring-2 ring-outline shadow-sticker-lg`; popovers, menus,
  selects, hover cards and combobox lists `ring-2 ring-outline shadow-sticker`. Overlay
  scrims stay solid without blur. Controls stay h-9 (+ pointer-coarse 44px).
- Layout: the public header shows the awning stripe (8px) above a 48px bar so the total
  header height remains 56px; the logo is round with an outline ring.

Per-feature rules:
1. Use semantic tokens and the sticker utilities. Do not add glass/backdrop-blur, glow
   blobs, neon or decorative gradients other than the awning stripe.
2. Keep: mask-image fades used for scroll affordance, skeleton shimmer/loading spinners,
   streaming indicators, chart colours (`--chart-*`, mapped to the brand palette),
   status semantic colours with text/icon.
3. Raw palette colours used decoratively (e.g. `text-amber-500`) → semantic tokens or brand
   accent variables. Fixed brand hex values are allowed only inside brand illustrations
   (`src/features/home/components/keyyi-stall-illustration.tsx`). Keep provider logos untouched.
4. Contrast MUST meet WCAG 2.1 AA: 4.5:1 for text tokens and 3:1 for input outlines. Use the
   palette pastels (#FF9E4A, #76BA99, #FF7B7B) as fills with chestnut text, not as text on
   light surfaces.
5. Typography: page titles 24–28px; the landing hero may use `text-5xl` with `font-brand`.
6. Never change business logic, data, billing/amount formatting, permissions or routes,
   or remove features/controls. Never touch QuantumNous/New API copyright headers,
   attribution or links. Site branding is set in `src/config/site.ts`.
7. Reuse existing components (AGENTS.md §3.3). No new UI system, no global `* !important`.
8. After edits run typecheck, explicit behavior tests and changed-file lint. The measured
   lint baseline is `docs/tools/frontend-lint-baseline.json` relative to the Git root;
   reject new diagnostics and remove fixed entries. Do not disable rules to obtain a pass.
