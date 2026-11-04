# AGENTS.md (TauAPI monorepo root)

This project is maintained by AI agents. Read this file first, then `map.md`, then `tauapi-ops/STATUS.md`.

## Documentation language policy

- **Human-facing documents are written in Simplified Chinese (简体中文).** These are documents a person reads
  to understand or operate the system:
  `README.md`, `map.md`, `tauapi-ops/HANDOFF.md`, `tauapi-ops/evidence/*.md` (acceptance and drill reports).
- **AI-facing documents are written in English.** These are instructions and working state for agents:
  every `AGENTS.md`, `tauapi-ops/STATUS.md`, `DECISIONS.md`, `PLAN.md`, `tauapi-ops/docs/*.md`,
  `tauapi-be/REPOSITORY_SPLIT.md`, `.agents/**`, code comments, commit messages, script output and log text.
- When you add a new document, decide who reads it and follow the matching language. If both, keep the
  AI-facing instructions in English and put the human summary in a Chinese document.
- When you change a fact in one language, update the matching document in the other (e.g. `HANDOFF.md` vs `STATUS.md`).
- Do not translate upstream-owned files (`LICENSE`, `NOTICE`, upstream READMEs in other languages,
  `THIRD-PARTY-LICENSES.md`, `UPSTREAM_ROOT_AGENTS.md`) — keep them byte-identical to upstream to keep subtree merges clean.
- Identifiers, commands, paths, tags and product names are never translated.
