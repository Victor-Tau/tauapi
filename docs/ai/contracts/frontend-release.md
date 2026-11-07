# Frontend release

## Intended behavior and invariants

FER-1: Build releases use `/_ui/<release>/` immutable assets; entry HTML and version metadata
are uncacheable. Missing assets are 404, not HTML. Preserve previous assets for open tabs.
FER-2: Deploy publishes the versioned assets before atomically switching `current/frontend`.
Rollback selects an existing validated release. Release notices must not force unsafe replay
or silently replace a working tab during a user operation.
FER-3: Supported API versions/capabilities or a validated support list define compatibility.
Git commit hashes have no semantic version order. Current `compatible_backend` is a declaration
logged by deploy, not an executable rejection gate. Verify mixed frontend/backend combinations
before release. Asset retention/pruning requires old-tab and rollback evidence.

Validation: typecheck/test/build, isolated frontend export, Nginx cache/404 checks,
old-tab chunk load, version notice, deploy/rollback drills in isolated QA.

## Sources and change procedure

- `tauapi-ops/scripts/build-frontend.sh`
- `tauapi-ops/scripts/deploy-frontend.sh`
- `tauapi-ops/scripts/rollback-frontend.sh`
- `tauapi-fe/rsbuild.config.ts`
- `tauapi-fe/src/hooks/use-release-update-notice.ts`


FER-4: Retain source regression tests in Git and run checks before building. Package only runtime dist assets. The builder rejects test source/config files and tests, __tests__, testdata, e2e, qa or coverage directories in dist.


FER-5: Version displays distinguish the frontend bundle from the running backend.
The frontend version is baked in from `VITE_REACT_APP_VERSION`, with the component's
`VERSION` file as the local-build fallback. An open tab retains its own frontend version
when another release goes live. `/api/status.data.backend_version` identifies the running
backend; `data.version` remains an equal compatibility alias for older frontends. New
frontends fall back to `data.version` when talking to older backends. Missing versions
are displayed as unknown, never borrowed from the other release unit. Update comparison
continues to use the backend semantic version; frontend release notices remain independent.

FER-6: Follow the [root release requirements](../../../AGENTS.md#release-requirements).
Frontend archives contain runtime assets and manifests without SHA256 checksum files
or sidecars. Deploy and rollback must work without them. Validate paths, manifest identity
and referenced assets before switching. Compare complete retained/public file paths and
bytes without hashing; reject changed, missing or extra immutable assets. Legacy releases
may retain a root checksum list, but no workflow reads or verifies its checksums.

## Frontend presentation ownership

FER-7: Each frontend release owns presentation in `tauapi-fe/src/config/site.ts`:
brand name, logo, favicon, footer, documentation URL, page/legal content, notice,
announcements, dashboard panels, chat presets, release repository and navigation. API status and legacy
browser snapshots cannot override these values. Sidebar preferences are account-scoped
browser data. The backend exposes business capabilities and authorization policies,
not frontend content, layout or navigation configuration. Currency conversion metadata
remains part of the billing API contract because it also defines payment input units.
Removed presentation APIs intentionally break compatibility with older frontends;
deploy the matching frontend before the backend. No server-side content migration or
automatic transfer of historical custom content is performed.
