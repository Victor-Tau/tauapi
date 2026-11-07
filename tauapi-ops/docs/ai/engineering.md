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

Changed-module tests only -> candidate subtree archive -> Bun typecheck/build -> versioned artifact/manifest -> publish immutable assets -> atomic current switch -> old-tab/version/rollback checks.

- [frontend-release](../../../docs/ai/contracts/frontend-release.md)

Selected checks: isolated-builds. See registry for literal runners and prerequisites.
Inspect manifest identity, retained/public file equality, missing chunk 404, cache headers and retained releases. compatible_backend is logged only; do not infer compatibility enforcement.

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

Pinned upstream revision -> faithful source import reviewed on main -> policy/fixture/VERSION/license review -> candidate checks on main.

- [routing-and-origin](../../../docs/ai/contracts/routing-and-origin.md)
- [billing-and-quota](../../../docs/ai/contracts/billing-and-quota.md)
- [task-plugins](../../../docs/ai/contracts/task-plugins.md)

Selected checks: docs-integrity, fixture-equality, isolated-builds. See registry for literal runners and prerequisites.
Inspect AGENTS/CLAUDE/.agents/import mapping even without merge conflicts. Compare local fixture evolution separately from UPSTREAM import hashes; sync must not deploy.

## Release commands

Run from `tauapi-ops/` with an authorized release target. Build from an explicit committed
candidate and keep its artifact IDs. Builders export only the selected component subtree.
Test only new or modified modules through explicit package/file/case targets before
building. Full suites are prohibited. Builders and isolated-build acceptance are build-only
and do not launch tests; never expand tests automatically to unchanged modules.

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

Perform upstream integration on the existing `main` branch. Branch creation is prohibited.
Do not run `scripts/sync-upstream.sh` or the current branch-producing importer workflow:
they create vendor/upgrade branches and must be adapted before future use. Import pinned
source content into the main worktree without creating refs. Review imported AGENTS, CLAUDE,
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
outside the source tree. Put the candidate frontend's `.node-version` runtime on PATH
alongside its locked Bun version before running frontend checks or builds.
`build-frontend.sh --out DIRECTORY` runs typecheck and builds without launching tests.
Run explicit tests only for new or modified modules separately.
`build-backend-binaries.sh` exports only `tauapi-be`, builds the independent libraries,
and creates one CGO-free linux-amd64 archive
with the executable, manifest and upstream notices. `build-backend.sh` explicitly builds
Docker images for `linux/amd64`. Do not build other release targets. Frontend assets remain
platform-independent. Both release units retain their own source/version metadata.
Building packages does not establish schema compatibility.

Every release must follow the [root release requirements](../../../AGENTS.md#release-requirements):

- Write the release body in Simplified Chinese and list only changes or updates.
- Do not add installation/deployment commands, build/test reports, platform/asset lists,
  checksums, credits, publication details or other commentary to the body. Technical
  identifiers may retain their original spelling within a Chinese change description.
- Write and review a notes file explicitly; never use generated GitHub release notes.
- Do not perform SHA256 verification or operations. Do not generate, package or upload
  `.sha256`, `SHA256SUMS`, `checksums-linux.txt`, SHA256 values or checksum metadata.
- Use a new, empty output directory. Review archive members and use an explicit upload
  allowlist of intended archives and frontend manifests; never upload a directory glob.
  Keep the Docker builder JSON local because its image ID contains digest metadata.
  Exclude deployment observations, evidence and upstream lock metadata from the public
  operations package; retain those source records in Git.
- Check candidate/version identity, archive structure, required files and runtime health.
  Frontend deploy/rollback compares retained and public file paths and bytes directly;
  it requires no checksum sidecar and still refuses to overwrite different immutable assets.

```bash
candidate=$(git rev-parse HEAD)
version=$(git show "$candidate:tauapi-be/VERSION")
assets=$(mktemp -d /tmp/tauapi-release-assets.XXXXXX)
BUN_BIN=$(command -v bun) scripts/build-frontend.sh --repo .. --rev "$candidate" \
  --release-id "fe-v${version}-${candidate:0:12}" --compat-backend "=$version" \
  --out "$assets"
scripts/build-backend-binaries.sh --repo .. --rev "$candidate" --out "$assets"
scripts/build-backend.sh --repo .. --rev "$candidate" --tag "tauapi-be:$version" --out "$assets"
docker save "tauapi-be:$version" | gzip > "$assets/tauapi-be-v${version}-docker-linux-amd64.tar.gz"
ops_package=$(mktemp -d)
git archive "$candidate:tauapi-ops" | tar -x -C "$ops_package"
rm -rf "$ops_package/evidence" "$ops_package/DEPLOYMENT_STATE.json" "$ops_package/UPSTREAM_LOCK.json"
for notice in LICENSE NOTICE THIRD-PARTY-LICENSES.md; do
  git show "$candidate:tauapi-be/$notice" > "$ops_package/$notice"
done
tar -czf "$assets/tauapi-ops-v${version}.tar.gz" -C "$ops_package" .
rm -rf "$ops_package"
```

Keep the Docker builder JSON alongside its image archive; its image ID, candidate and
version identify the image accepted by the existing deploy script. Publish only after
candidate checks and archive/content review. GitHub Actions stay disabled. Perform every
release operation on `main`; never create a release or candidate branch. Push the reviewed
`main` commit and an annotated `v<version>` tag; create a draft GitHub Release with
`--notes-file <reviewed-notes-file>` (never `--generate-notes`), upload only the explicit
allowlist, then publish it as latest. Recheck the body against the change-only Chinese rule
and confirm that no SHA256 checksum content is attached before publication. Confirm the
public feed exposes that tag and all expected assets. Publishing and production deployment require separate authorization.

On an existing configured linux-amd64 host, download assets into an empty staging directory.
Check the selected tag, candidate/version metadata, archive structure and required files.
Stage only the frontend tar under `/srv/tauapi/artifacts/frontend/`; do not fetch or verify
SHA256 sidecars. Keep the locally produced Docker builder JSON with the backend artifact
records for the existing deploy script. Load the Docker archive before the authorized rollout:

```bash
gzip -dc tauapi-be-v1.0.1-docker-linux-amd64.tar.gz | sudo docker load
sudo scripts/deploy-frontend.sh fe-v1.0.1-<candidate-prefix>
sudo scripts/deploy-backend.sh tauapi-be:1.0.1
```

Use the release's actual frontend ID and backend tag. Keep previous frontend releases;
the backend rollout drains requests/SSE/WS and can pause on long connections. Application
rollback remains subject to BER-2/BER-3 and the known schema compatibility gaps. The UI
checks and links releases; it does not download artifacts or execute server deployments.
