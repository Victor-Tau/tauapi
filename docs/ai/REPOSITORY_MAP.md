# Repository and release boundaries

TauAPI derives from QuantumNous/new-api. One Git repository contains:

| Area | Runtime responsibility | Build boundary |
| --- | --- | --- |
| tauapi-fe | React/TypeScript/Rsbuild static console | git archive REV:tauapi-fe; Bun |
| tauapi-be | Gin API gateway, relay, auth, billing, task host | git archive REV:tauapi-be; Go |
| tauapi-ops | Nginx split contract, build/release, backup and QA scripts | host tooling |

Browser -> Nginx -> explicit page/assets or API backend -> middleware -> controller ->
service/model or relay/provider. Backend NoRoute tries plugins before uncached JSON 404.
Browser API calls remain same-origin relative URLs. The backend embeds no SPA.
Master and slave share primary database and secrets; only master owns migrations/tasks.
Redis topology affects cache revocation latency and rate-limit scope.

The host, RelayKit and TokenKit are three Go modules. Libraries build with GOWORK=off.
RelayKit handles protocol DTO/conversion; TokenKit counts tokens without transport/billing.
Frontend/backend share expression semantics through separately stored fixture copies.
Root tooling synchronizes them without coupling isolated builds.

Production conventions use `/srv/tauapi`, secrets `/etc/tauapi`, local backups
`/var/backups/tauapi`, Nginx TLS, loopback backend ports 3001/3002 and Docker data networks.
QA uses separate names/volumes, loopback 8443 and 3101/3102; never infer its running state.
`tauapi-ops/DEPLOYMENT_STATE.json` is a generated timestamped snapshot.
Imported nested workflows do not run as root GitHub Actions workflows.
