# TauAPI frontend policy

The root policy applies. Select affected contracts through [the task index](../docs/ai/INDEX.md).
Read [shared engineering](../docs/ai/engineering.md) and [frontend engineering](docs/ai/engineering.md)
before code work. `UPSTREAM_ROOT_AGENTS.md` is the preserved upstream reference.

For UI work, read `.agents/skills/shadcn-ui/SKILL.md`, search shared business components,
and inspect implementations and call sites before adding a component. Follow the local
engineering rules for reuse, theme, accessibility, error handling and i18n.

Use Bun, React/TypeScript, TanStack routing/query and the shared HTTP client.
Business URLs are same-origin and relative. Tokens stay out of Web Storage.
Use flat English translation keys and `toIntlLocale` for interface-derived Intl locales.
Run typecheck for TS/TSX changes, relevant behavior tests and lint on changed code.
Test only new or modified modules through explicit test files or cases. Full frontend
or repository test suites and unfiltered test commands are prohibited.

Read billing contracts for pricing, usage and expression changes. The frontend consumes
its own fixture snapshot; root tooling synchronizes it with the backend. `UPSTREAM.json`
records the original import. Build/runtime imports stay within this component.
Update local engineering guidance and root contracts when behavior changes.
