# Minimalist Flat — implementation rules for tauapi-fe

Source of truth: GOAL.md §9. Shared layer already done (do not redo):
- `src/styles/theme.css`: semantic tokens mapped (bg #FAFAFA/#111111, card #FFF/#1B1B1B,
  muted #F5F5F5/#262626, fg #171717/#F5F5F5, muted-fg #525252/#A3A3A3, border #E5E5E5/#333,
  input #737373, primary #1D4ED8/#93C5FD, primary-fg #FFF/#111827, ring #2563EB/#93C5FD),
  `--radius` 6px, `rounded-2xl/3xl/4xl` capped at 8px.
- `src/styles/theme-presets.css`: presets change accent only; surfaces stay neutral.
- `src/styles/index.css`: no card hover lift, no press scale, no table row entrance,
  glass-* = solid card + border, appear/landing animations = 0.2s opacity fade.
- `src/components/ui/*`: overlays solid scrim (bg-black/40, no blur), no shadow-md/lg on
  popovers, `ring-border` hairlines, solid focus ring, controls h-9 (+ pointer-coarse 44px).
- layout: public header, sidebar inset, footer, drawers, floating window flattened.

Per-feature rules:
1. Remove decorative gradients (`bg-gradient-*`, `bg-linear-*`, `bg-radial`, `from-*/via-*/to-*`
   used for decoration, inline `linear-gradient` backgrounds), glass/backdrop-blur, glow/blur
   blobs, neon, hover scale/translate, decorative `shadow-*`. Replace with `bg-card`/`bg-muted`
   + `border` and semantic tokens.
2. Keep: mask-image fades used for scroll affordance, skeleton shimmer/loading spinners,
   streaming indicators, chart colours (`--chart-*`), status semantic colours with text/icon,
   `rounded-full` on avatars/dots/switches/pills that are semantically round.
3. Raw palette colours used decoratively (e.g. `text-amber-500`, `bg-violet-500/10`) → semantic
   tokens (`text-primary`, `bg-muted`, `text-muted-foreground`, `text-success`, `text-warning`,
   `text-destructive`). Keep provider/brand logos untouched.
4. Typography: page titles 24–28px (`text-2xl`/`text-[28px]` max), section titles 18–20px;
   oversized hero type (`text-5xl+`) reduced to `text-3xl/4xl` on landing only.
5. Never change business logic, data, billing/amount formatting, i18n keys, permissions, routes,
   or remove features/controls. Never touch QuantumNous/New API branding, copyright headers,
   attribution or links.
6. Reuse existing components (AGENTS.md §3.3). No new UI system, no global `* !important`.
7. After edits: `bun run typecheck` must pass; `bunx oxlint -c .oxlintrc.json <changed files>`
   must not add new errors versus `git stash`-free baseline (upstream already has 152 errors;
   compare per-file counts with `git show vendor/upstream:<path>`).
