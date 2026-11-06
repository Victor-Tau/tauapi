# Known gaps and executable follow-ups

Source review at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; no production mutations were performed.

| ID | Gap and source | Required follow-up evidence |
| --- | --- | --- |
| GAP-1 | Old DEPLOYMENT starts slave before setup prerequisite | Master-only -> TLS/frontend -> admin init -> restart master -> slave; fresh-host isolated drill |
| GAP-2 | deploy-frontend logs compatible_backend only | Version/capability producer + rejecting gate + incompatible deployment test |
| GAP-3 | deploy-backend omits schema_changed; direct --rollback bypasses wrapper | Reliable schema producer + shared validator on every entry + unknown/incompatible rejection |
| GAP-4 | generate-nginx optional regex conflict scan misses dynamic routes | Runtime registration audit and direct-load/fallback/plugin behavior coverage |
| GAP-5 | model migration tests skip absent DSNs | Required real DB profile, fresh/upgrade/two-start/log DB evidence and minimum versions when relevant |
| GAP-6 | Hosted CI intentionally retired by user decision | Run selected checks locally; no GitHub Actions workflow or hosted required check is expected |
| GAP-7 | A candidate may edit its own checker | Independent review of governance changes; local candidate pass alone is not independent assurance |
| GAP-8 | Claude instructions/hooks need actual loading observation | Installed-client version plus root/component/resume/rule runtime drills without provider operations |

Documentation explains gaps immediately; it does not close runtime gaps 2–5.
No background semantic-repair service, production deployment or remote policy activation is implied.


## Tool integration limits observed during bootstrap

Bootstrap observation: Claude Code 2.1.316 loaded AGENTS.md through CLAUDE.md imports,
and direct component launches showed an ancestor-import trust prompt. Those adapters have
now been removed. On 2026-11-06, fresh interactive sessions with the same installed version
showed AGENTS.md directly in root /memory; each of the three component sessions listed
both /opt/tauapi/AGENTS.md and its local AGENTS.md, without an import trust prompt.
Only the local /memory command was used; no model prompt was submitted. Root/component
native instruction discovery is observed; the broader GAP-8 drills below remain open.
The optional root launcher remains available. No trust setting was changed.
Relevant/irrelevant path-rule activation, model-assisted recovery after compaction and delegated
runtime sessions remain not_run; no provider prompt or provider request was issued.
User/global configuration keys were inspected without exposing values; no user/global hook
registrations or claudeMdExcludes were present. Existing user settings were not changed.
Current 2026-11-06 observation: repository Actions permissions are disabled and the five historical
runs were deleted. No Actions secrets, variables, rulesets or main branch protection were configured.
Root and nested workflow source files are removed. Independent governance review remains GAP-7;
local validation does not establish that trust boundary.
