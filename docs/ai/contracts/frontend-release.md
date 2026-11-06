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

Review consumers and contract dispositions together; execute selected checks on the actual candidate.
Verification basis: source inspection at e2af94c1affa0d760cd6dd5fb4c57117949e9e6f; no live deployment check.

FER-4: Retain source regression tests in Git and run checks before building. Package only runtime dist assets. The builder rejects test source/config files and tests, __tests__, testdata, e2e, qa or coverage directories in dist.
