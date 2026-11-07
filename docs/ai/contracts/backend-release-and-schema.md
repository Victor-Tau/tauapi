# Backend release and schema

## Intended behavior and invariants

BER-1: Master performs migrations and background work; slave startup requires initialized setup.
Rolling release removes one instance, drains requests/SSE/WS, replaces and health/setup-checks
it before readmission. Mixed-version requests must preserve auth, schema and billing contracts.
If drain cannot safely complete, pause and recover the recorded upstream state.
BER-2: Application rollback and data recovery are separate operations. A backup does not prove
an old binary can read a new schema. Unknown schema compatibility must stay unknown.
The current deploy record omits `schema_changed`; wrapper defaults and direct --rollback do not
establish a shared compatibility gate.
BER-3: A future reliable build/migration producer must emit schema status (none/changed/unknown),
migration IDs, old/new app compatibility, tested revision, evidence and rollback method.
Manually supplied fields alone cannot establish safety. Every rollback entry must use one validator.

Database changes retain SQLite/MySQL >=5.7.8/PostgreSQL >=9.6 support, including separate log DBs
where applicable. Run real fresh and released-schema upgrade tests, startup twice, preserve data,
indexes, uniqueness and constraints. Missing DSNs/services or skipped tests block completion.
Record exact engine versions. Version-specific work includes minimum supported versions.

## Sources and change procedure

- `tauapi-ops/scripts/deploy-backend.sh`
- `tauapi-ops/scripts/rollback-backend.sh`
- `tauapi-ops/scripts/bootstrap-stack.sh`
- `tauapi-be/model/main.go`
- `tauapi-be/model/locking.go`


BER-4: Source regression tests remain in Git. The runtime image copies the Go executable and required licenses, not builder sources. The release builder rejects application test-source paths in the final image. This does not prohibit OS utilities whose names contain test.
