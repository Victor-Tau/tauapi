# Open implementation work

Reviewed against source at `cc57ebd0600e2c87c994b5ee4ea6d74ad2bb52c5`.

| ID | Current behavior | Completion check |
| --- | --- | --- |
| GAP-1 | Fresh-host steps now order HTTP ACME, certificate, master, setup and slave; the full clean-host drill is pending | Run [fresh-host](../../tauapi-ops/docs/ai/runbooks/fresh-host.md) in an isolated environment |
| GAP-2 | `deploy-frontend.sh` logs `compatible_backend` without rejecting incompatible backends | Add a version/capability gate and test incompatible releases |
| GAP-3 | `deploy-backend.sh` omits `schema_changed`; direct `--rollback` and the wrapper have different validation paths | Add a schema-status producer and one validator for all rollback paths |
| GAP-4 | `generate-nginx.py` scans literal plugin routes and misses dynamic registrations | Test runtime registration, direct navigation and plugin fallback |
| GAP-5 | Model tests skip MySQL/PostgreSQL cases when DSNs are absent | Run real fresh/upgrade/two-start tests for primary and affected log databases |

Release and persistence contracts define the required behavior. These entries track the
remaining implementation and execution work.
