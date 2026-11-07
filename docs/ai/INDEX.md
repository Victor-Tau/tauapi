# Technical index

Generated from registry.yaml by `make docs-generate`.

Read the [root policy](../../AGENTS.md), then select affected domains below.
[Shared engineering](engineering.md) covers common code and contribution rules.
[Maintenance](workflows/docs-maintenance.md) covers records, tooling and verification.
[Known gaps](KNOWN_GAPS.md) lists unfinished controls. [System map](../map.md) explains architecture.

| Domain | Required reads | Checks |
| --- | --- | --- |
| be-auth | [authentication](contracts/authentication.md), [be-engineering](../../tauapi-be/docs/ai/engineering.md), [be-policy](../../tauapi-be/AGENTS.md) | backend-tests |
| be-billing | [be-engineering](../../tauapi-be/docs/ai/engineering.md), [be-policy](../../tauapi-be/AGENTS.md), [billing-and-quota](contracts/billing-and-quota.md) | backend-tests, billing-fe, billing-go, fixture-equality |
| be-general | [be-engineering](../../tauapi-be/docs/ai/engineering.md), [be-policy](../../tauapi-be/AGENTS.md) |  |
| be-libraries | [be-engineering](../../tauapi-be/docs/ai/engineering.md), [be-library-guide](../../tauapi-be/docs/ai/independent-libraries.md), [be-policy](../../tauapi-be/AGENTS.md), [billing-and-quota](contracts/billing-and-quota.md) | backend-tests, libraries-build |
| be-persistence | [authentication](contracts/authentication.md), [backend-release-and-schema](contracts/backend-release-and-schema.md), [be-engineering](../../tauapi-be/docs/ai/engineering.md), [be-policy](../../tauapi-be/AGENTS.md), [billing-and-quota](contracts/billing-and-quota.md) | backend-tests, database-matrix |
| be-plugins | [be-engineering](../../tauapi-be/docs/ai/engineering.md), [be-policy](../../tauapi-be/AGENTS.md), [billing-and-quota](contracts/billing-and-quota.md), [routing-and-origin](contracts/routing-and-origin.md), [task-plugins](contracts/task-plugins.md) | backend-tests, plugins-format, plugins-lint, route-analysis |
| be-relay | [be-engineering](../../tauapi-be/docs/ai/engineering.md), [be-policy](../../tauapi-be/AGENTS.md), [billing-and-quota](contracts/billing-and-quota.md), [routing-and-origin](contracts/routing-and-origin.md) | backend-tests, route-analysis |
| be-status | [be-engineering](../../tauapi-be/docs/ai/engineering.md), [be-policy](../../tauapi-be/AGENTS.md), [frontend-release](contracts/frontend-release.md) | backend-tests |
| fe-auth | [authentication](contracts/authentication.md), [fe-engineering](../../tauapi-fe/docs/ai/engineering.md), [fe-policy](../../tauapi-fe/AGENTS.md) | frontend-tests, frontend-typecheck |
| fe-billing | [billing-and-quota](contracts/billing-and-quota.md), [fe-billing-semantics](../../tauapi-fe/docs/ai/billing-presentation.md), [fe-engineering](../../tauapi-fe/docs/ai/engineering.md), [fe-policy](../../tauapi-fe/AGENTS.md), [task-plugins](contracts/task-plugins.md) | billing-fe, fixture-equality, frontend-typecheck |
| fe-data | [authentication](contracts/authentication.md), [fe-engineering](../../tauapi-fe/docs/ai/engineering.md), [fe-policy](../../tauapi-fe/AGENTS.md), [routing-and-origin](contracts/routing-and-origin.md) | frontend-tests, frontend-typecheck |
| fe-general | [fe-engineering](../../tauapi-fe/docs/ai/engineering.md), [fe-policy](../../tauapi-fe/AGENTS.md) |  |
| fe-shell | [fe-engineering](../../tauapi-fe/docs/ai/engineering.md), [fe-policy](../../tauapi-fe/AGENTS.md), [frontend-release](contracts/frontend-release.md), [routing-and-origin](contracts/routing-and-origin.md) | frontend-build, frontend-tests, frontend-typecheck, route-analysis |
| fe-ui | [fe-design](../../tauapi-fe/docs/ai/theme-and-accessibility.md), [fe-engineering](../../tauapi-fe/docs/ai/engineering.md), [fe-policy](../../tauapi-fe/AGENTS.md) | frontend-lint, frontend-tests, frontend-typecheck |
| governance | [root-index](INDEX.md), [root-policy](../../AGENTS.md) | docs-integrity, docs-tests |
| ops-backend | [backend-release-and-schema](contracts/backend-release-and-schema.md), [ops-engineering](../../tauapi-ops/docs/ai/engineering.md), [ops-policy](../../tauapi-ops/AGENTS.md) | isolated-builds |
| ops-backup | [backend-release-and-schema](contracts/backend-release-and-schema.md), [ops-engineering](../../tauapi-ops/docs/ai/engineering.md), [ops-policy](../../tauapi-ops/AGENTS.md) | shell-syntax |
| ops-frontend | [frontend-release](contracts/frontend-release.md), [ops-engineering](../../tauapi-ops/docs/ai/engineering.md), [ops-policy](../../tauapi-ops/AGENTS.md) | isolated-builds |
| ops-general | [ops-engineering](../../tauapi-ops/docs/ai/engineering.md), [ops-policy](../../tauapi-ops/AGENTS.md) |  |
| ops-routing | [ops-engineering](../../tauapi-ops/docs/ai/engineering.md), [ops-policy](../../tauapi-ops/AGENTS.md), [routing-and-origin](contracts/routing-and-origin.md) | route-analysis |
| ops-upstream | [billing-and-quota](contracts/billing-and-quota.md), [ops-engineering](../../tauapi-ops/docs/ai/engineering.md), [ops-policy](../../tauapi-ops/AGENTS.md), [routing-and-origin](contracts/routing-and-origin.md), [task-plugins](contracts/task-plugins.md) | docs-integrity, fixture-equality, isolated-builds |

[Task records](changes/active/) contain the current scope and check results.
