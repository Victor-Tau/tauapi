# TauAPI operations policy

The root policy applies. Read [operations engineering](docs/ai/engineering.md).
Use repository-relative paths for source and explicit target paths for runtime state.
`DEPLOYMENT_STATE.json` records deployment observations with their collection time.

## Authority and boundaries

A documentation task does not authorize deployments or production database changes.
Never run `docker compose down -v`, delete named `tauapi_*` volumes, regenerate
existing secrets, overwrite production with a restore, or print secret values.
Do not modify SSH access/firewall without explicit authorization.
Restoration drills use isolated databases. Backups need a separately configured off-site copy.
Do not push to QuantumNous upstream or remove protected attribution.
All deploy/switch/rollback operations share `/run/lock/tauapi-deploy.lock`.
Do not delete a held lock to bypass another operation.

## Required reads

Read the routing contract for Nginx changes, release contracts for deploy/build changes,
and backend persistence guidance for schema or database work.
Master-only bootstrap precedes admin initialization, master restart, and slave startup.
Keep maintenance mode until setup, TLS, frontend and smoke prerequisites pass.
Unknown compatibility is unknown; existing scripts do not establish schema-safe rollback.
See [known gaps](../docs/ai/KNOWN_GAPS.md) before relying on a release safeguard.

## Maintenance

Builders export the supplied revision's single subtree. Never certify a candidate
by building hardcoded main. Raw vendor imports stay faithful; integration of imported
AGENTS, CLAUDE, .agents, VERSION and licenses needs deliberate governance review.
Record environment, timestamp, release and command for every deployment observation.
Summarize user effects in root README, docs/map.md or docs/CHANGELOG.md.
Technical procedures and logs use English.
Run applicable script syntax checks, docs checks and isolated QA checks within scope.
