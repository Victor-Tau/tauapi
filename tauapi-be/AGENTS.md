# TauAPI backend policy

The root policy applies. Select affected contracts through [the task index](../docs/ai/INDEX.md).
Read [shared engineering](../docs/ai/engineering.md) and [backend engineering](docs/ai/engineering.md)
before code work.

Read the authentication contract for security work. Read the billing contract in full
before planning, coding or reviewing quantities, usage extraction, prices, passthrough,
multipart multipliers, quota, reservation, settlement or refund behavior.

RelayKit cannot import the host. TokenKit cannot import the host or RelayKit.
Verify each affected library with `GOWORK=off go build ./...` and relevant tests.
Run tests only for new or modified packages or cases, one module at a time.
Full backend/repository suites, recursive `go test ./...` and testing unchanged modules
are prohibited. Do not use an unfiltered aggregate test target.
Host JSON operations use `common.*`; RelayKit uses `kitutil.*`.
Keep plugin specifications in `docs/plugin-api/`; add no documentation under `plugins/`.

Database behavior changes require real SQLite, MySQL and PostgreSQL checks, including
fresh schema, released-schema upgrades, two startups, preservation of data/indexes/constraints,
and affected log databases. Missing DSNs or skipped tests leave verification incomplete.
The local engineering policy defines supported versions and database coding rules.
Update local engineering guidance and root contracts when behavior changes.
