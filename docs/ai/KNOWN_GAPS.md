# Known gaps and executable follow-ups

Source review at baseline e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; no production mutations were performed.

| ID | Gap and source | Required follow-up evidence |
| --- | --- | --- |
| GAP-1 | Old DEPLOYMENT starts slave before setup prerequisite | Master-only -> TLS/frontend -> admin init -> restart master -> slave; fresh-host isolated drill |
| GAP-2 | deploy-frontend logs compatible_backend only | Version/capability producer + rejecting gate + incompatible deployment test |
| GAP-3 | deploy-backend omits schema_changed; direct --rollback bypasses wrapper | Reliable schema producer + shared validator on every entry + unknown/incompatible rejection |
| GAP-4 | generate-nginx optional regex conflict scan misses dynamic routes | Runtime registration audit and direct-load/fallback/plugin behavior coverage |
| GAP-5 | model migration tests skip absent DSNs | Required real DB profile, fresh/upgrade/two-start/log DB evidence and minimum versions when relevant |
| GAP-6 | Nested backend CI is not root enforcement | Root candidate workflow plus observed remote run and required branch rule |
| GAP-7 | A candidate may edit its own checker | Trusted baseline/protected reusable validation; local candidate pass alone is not independent assurance |
| GAP-8 | Claude adapters/hooks need actual loading observation | Installed-client version plus root/component/resume/rule runtime drills without provider operations |

Documentation explains gaps immediately; it does not close runtime gaps 2–5.
No background semantic-repair service, production deployment or remote policy activation is implied.


## Tool integration limits observed during bootstrap

Claude Code 2.1.316 is installed. A real root session /memory listed CLAUDE.md and
@-imported AGENTS.md; the SessionStart hook ran. Direct launches from all three component
directories showed the external-import trust prompt for root AGENTS.md. No trust setting
was changed. The canonical launcher was tested from all three components and resolves root.
Relevant/irrelevant path-rule activation, model-assisted recovery after compaction and delegated
runtime sessions remain not_run; no provider prompt or provider request was issued.
User/global configuration keys were inspected without exposing values; no user/global hook
registrations or claudeMdExcludes were present. Existing user settings were not changed.
Remote CI and merge rules were not activated. Trusted independent governance validation
remains GAP-7; the candidate workflow alone cannot establish that trust boundary.
