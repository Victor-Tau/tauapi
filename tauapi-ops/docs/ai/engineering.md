# Operations engineering

Paths below are relative to the Git root.

## Source map

### Backend releases

- `tauapi-ops/scripts/deploy-backend.sh`
- `tauapi-ops/scripts/rollback-backend.sh`
- `tauapi-ops/scripts/bootstrap-stack.sh`

Candidate API-only archive -> image -> remove instance from upstream -> drain -> master/slave replacement and setup/health checks -> readmission -> release record.

- [backend-release-and-schema](../../../docs/ai/contracts/backend-release-and-schema.md)

Selected checks: isolated-builds. See registry for literal runners and prerequisites.
Inspect migration ownership, unknown schema state, mixed-version semantics, SSE/WS drain and paused recovery. App rollback cannot prove data rollback safety.

### Backup and restore

- `tauapi-ops/scripts/backup.sh`
- `tauapi-ops/scripts/restore-check.sh`

Scheduled/authorized backup -> DB dump plus Git/meta -> isolated restore -> table/root/app-read assertions -> dated evidence.

- [backend-release-and-schema](../../../docs/ai/contracts/backend-release-and-schema.md)

Selected checks: shell-syntax. See registry for literal runners and prerequisites.
Inspect backup exit status, permissions, isolated target and off-site availability. Never overwrite production or remove named volumes for a drill.

### Frontend releases

- `tauapi-ops/scripts/build-frontend.sh`
- `tauapi-ops/scripts/deploy-frontend.sh`
- `tauapi-ops/scripts/rollback-frontend.sh`

Candidate subtree archive -> Bun typecheck/tests/build -> versioned artifact/manifest -> publish immutable assets -> atomic current switch -> old-tab/version/rollback checks.

- [frontend-release](../../../docs/ai/contracts/frontend-release.md)

Selected checks: isolated-builds. See registry for literal runners and prerequisites.
Inspect manifest hashes, missing chunk 404, cache headers and retained releases. compatible_backend is logged only; do not infer compatibility enforcement.

### Routing

- `tauapi-ops/ROUTE_CONTRACT.json`
- `tauapi-ops/scripts/generate-nginx.py`

ROUTE_CONTRACT -> generate-nginx -> reviewed config -> nginx -t -> authorized switch -> page/API/plugin/cache/404 observations.

- [routing-and-origin](../../../docs/ai/contracts/routing-and-origin.md)

Selected checks: route-analysis. See registry for literal runners and prerequisites.
Inspect backend-exceptions-first ordering and reserved namespaces. Literal regex scanning is partial coverage; test dynamic plugin reachability separately.

### Upstream synchronization

- `tauapi-ops/scripts/import-upstream.py`
- `tauapi-ops/scripts/sync-upstream.sh`
- `tauapi-ops/UPSTREAM_LOCK.json`

Pinned SHA -> faithful vendor branches -> task upgrade branch subtree merges -> policy/fixture/VERSION/license review -> candidate tests -> deliberate merge.

- [routing-and-origin](../../../docs/ai/contracts/routing-and-origin.md)
- [billing-and-quota](../../../docs/ai/contracts/billing-and-quota.md)
- [task-plugins](../../../docs/ai/contracts/task-plugins.md)

Selected checks: docs-integrity, fixture-equality, isolated-builds. See registry for literal runners and prerequisites.
Inspect AGENTS/CLAUDE/.agents/import mapping even without merge conflicts. Compare local fixture evolution separately from UPSTREAM import hashes; sync must not deploy.

## Release commands

Run from `tauapi-ops/` with an authorized release target. Build from an explicit committed
candidate and keep its artifact IDs. Builders export only the selected component subtree.

```bash
candidate=$(git rev-parse HEAD)
scripts/build-frontend.sh --rev "$candidate" --release-id "fe-${candidate:0:12}"
scripts/build-backend.sh --rev "$candidate"
TAUAPI_VERIFY_REV="$candidate" scripts/verify-independent-builds.sh all
sudo scripts/deploy-frontend.sh <release-id>
sudo scripts/deploy-backend.sh <image-tag>
sudo scripts/smoke.sh --public
```

Frontend rollback uses `scripts/rollback-frontend.sh [release-id]`; backend rollback uses
`scripts/rollback-backend.sh` after reviewing schema compatibility under BER-2/BER-3.
`prune-frontend.sh` previews retention; `--apply` performs removal while retaining current,
rollback and recent releases. Backend exit 10 leaves a draining instance running with long
connections; recover the recorded upstream selection or retry after those connections end.

Use [fresh-host installation](runbooks/fresh-host.md) for setup and
[backup and recovery](runbooks/backup-and-recovery.md) for restore drills.
`collect-evidence.sh` records deployment time and artifacts in `DEPLOYMENT_STATE.json`
and an English summary under `evidence/`. Summarize user effects in `docs/CHANGELOG.md`
at the Git root.

## Upstream integration

Run `scripts/sync-upstream.sh <sha|tag>` to import pinned upstream revisions into vendor
branches and merge their subtrees on an upgrade branch. Review imported AGENTS, CLAUDE,
`.agents`, VERSION, license and fixture changes even when Git reports no conflict.
Keep raw vendor imports faithful and local VERSION values during integration. Run both
fixture consumers, affected application checks and candidate-specific isolated builds.
Apply root contracts to schema, authentication, billing, plugin and routing changes.

## Release channel

TauAPI uses its own semantic version in `tauapi-fe/VERSION` and `tauapi-be/VERSION`.
Update both for a coordinated release and retain them during upstream imports.
The browser checks the public GitHub Releases repository selected by `SystemUpdateRepository`,
defaulting to `Victor-Tau/tauapi`; `/api/status` supplies the effective repository and backend version.
Publish a matching `v<version>` tag for a release. Changing the repository changes the frontend
query/cache key. Source: `tauapi-fe/src/features/system-update/releases.ts` and
`tauapi-be/common/system_update.go`.

Build GitHub assets locally from an explicit committed candidate. Keep release artifacts
outside the source tree. `build-frontend.sh --out DIRECTORY --test-workers 1` supports
resource-limited hosts and retains all frontend checks. `build-backend-binaries.sh` exports
only `tauapi-be`, runs host/library checks, and creates CGO-free Linux amd64/arm64 archives
with the executable, manifests, checksums and upstream notices. Both release units retain
their own source/version metadata. Cross-compiled arm64 packages require target-host smoke
checks before production use. Building packages does not establish schema compatibility.

```bash
candidate=$(git rev-parse HEAD)
version=$(git show "$candidate:tauapi-be/VERSION")
assets=/tmp/tauapi-release-assets
mkdir -p "$assets"
BUN_BIN=$(command -v bun) scripts/build-frontend.sh --repo .. --rev "$candidate" \
  --release-id "fe-v${version}-${candidate:0:12}" --compat-backend "=$version" \
  --out "$assets" --test-workers 1
scripts/build-backend-binaries.sh --repo .. --rev "$candidate" --out "$assets"
scripts/build-backend.sh --repo .. --rev "$candidate" --tag "tauapi-be:$version" --out "$assets"
docker save "tauapi-be:$version" | gzip > "$assets/tauapi-be-v${version}-docker-linux-amd64.tar.gz"
ops_package=$(mktemp -d)
git archive "$candidate:tauapi-ops" | tar -x -C "$ops_package"
for notice in LICENSE NOTICE THIRD-PARTY-LICENSES.md; do
  git show "$candidate:tauapi-be/$notice" > "$ops_package/$notice"
done
tar -czf "$assets/tauapi-ops-v${version}.tar.gz" -C "$ops_package" .
rm -rf "$ops_package"
(cd "$assets" && find . -maxdepth 1 -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
```

Keep the Docker builder JSON alongside its image archive; its image ID, candidate and
version identify the image accepted by the existing deploy script. Publish only after
candidate checks and digest verification. GitHub Actions stay disabled. Push the reviewed
candidate branch and an annotated `v<version>` tag; create a draft GitHub Release, upload
verified assets, then publish it as latest. Confirm the public feed exposes that tag and
all expected assets. Publishing and production deployment require separate authorization.

On an existing configured host, download assets into an empty staging directory, verify
`sha256sum -c SHA256SUMS`, then stage the frontend tar and its `.sha256` under
`/srv/tauapi/artifacts/frontend/`. Load the Docker archive before the authorized rollout:

```bash
gzip -dc tauapi-be-v1.0.1-docker-linux-amd64.tar.gz | sudo docker load
sudo scripts/deploy-frontend.sh fe-v1.0.1-<candidate-prefix>
sudo scripts/deploy-backend.sh tauapi-be:1.0.1
```

Use the release's actual frontend ID and backend tag. Keep previous frontend releases;
the backend rollout drains requests/SSE/WS and can pause on long connections. Application
rollback remains subject to BER-2/BER-3 and the known schema compatibility gaps. The UI
checks and links releases; it does not download artifacts or execute server deployments.
