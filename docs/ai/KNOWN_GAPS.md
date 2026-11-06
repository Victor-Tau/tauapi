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

Claude Code 2.1.316 is installed. Thin adapters, canonical root launcher and hook adapters
are installed and tested locally. Live instruction loading, direct component trust,
resume/compaction and path-rule activation require an interactive client session; these
are not inferred from adapter files. No provider call was made for this migration test.
Remote CI and merge rules were not activated. Trusted independent governance validation
remains GAP-7; the candidate workflow alone cannot establish that trust boundary.
