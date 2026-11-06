# TauAPI agent documentation

> Proposed target: docs/ai/INDEX.md. The target paths below are rollout targets,
> not a statement that they already exist in the audited repository.

## Start here

Read the repository-root agent policy. Use `TASK_INDEX.md` to select the smallest
relevant reading set. Read `REPOSITORY_MAP.md` when the task spans components or
its owner is unclear. The registry is the source for generated routing tables.

## Choose a route

| Task | Domain | Cross-component contracts to consider |
| --- | --- | --- |
| UI behavior | Frontend feature and shared components | Frontend release; auth or billing if behavior touches them |
| New page or route | Frontend shell and operations routing | Routing and origin |
| Login, refresh, or permission defect | Frontend auth and backend auth | Authentication and authorization |
| Price, usage, count, or refund | Backend billing; frontend billing if exposed | Billing and quota |
| Provider or task plugin | Relay and plugins | Plugin protocol; billing; routing |
| Model/schema/driver change | Persistence and affected business domain | Schema and backend release |
| Deployment or rollback | Operations release domain | Frontend release or backend release/schema |
| Upstream upgrade | Upstream integration and changed domains | Union of contracts affected by imported changes |

## Follow the source

Domain cards identify source paths, symbols, meaningful tests, and known failure
boundaries. Verify them against the current revision. Examples and historical
reports are not current authority.

## Before completion

Re-run routing against the final diff. Record outcomes of required checks and
dispositions of affected documents. Link exact evidence, then write a concise
Chinese handoff. Unrun checks remain unrun.
