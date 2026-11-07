# Fresh-host installation

Run from `/opt/tauapi/tauapi-ops` on the authorized target host. Apply [operations policy](../../../AGENTS.md).
The complete sequence still needs an isolated clean-host drill (GAP-1).

## Prepare the host and candidate

Install Docker Engine with Compose, Nginx, certbot, Git, jq, rsync, Python 3, curl and OpenSSL.
Use an Ubuntu 24.04 x86_64 host with at least 4 GiB RAM, swap and 10 GiB free disk.
Point the domain A record to the host and make ports 80/443 reachable.
Install the Bun version in `tauapi-fe/package.json`; put Bun on PATH for build subprocesses.

Clone the repository into `/opt/tauapi` and give the build user ownership. Review domain
settings in `scripts/lib.sh`, `preflight.sh`, `generate-nginx.py`, `bootstrap-admin.py` and
`smoke-auth.py`, plus the timezone in `bootstrap-stack.sh`. Commit configuration changes.
Keep pinned container digests and the declared toolchain versions.

```bash
scripts/preflight.sh
candidate=$(git rev-parse HEAD)
scripts/build-backend.sh --rev "$candidate"
scripts/build-frontend.sh --rev "$candidate" --release-id "fe-${candidate:0:12}"
```

Builders export the committed candidate subtree. Record the backend image tag and frontend
release ID printed by the commands; use those exact values below. Require successful checks
and artifacts before installation.

## Establish HTTP ACME and issue the certificate

Create `/var/www/tauapi-acme`. Install an HTTP-only bootstrap site at
`/etc/nginx/sites-available/tauapi-bootstrap.conf`, replacing `<domain>`:

```nginx
server {
    listen 80;
    server_name <domain>;
    location ^~ /.well-known/acme-challenge/ { root /var/www/tauapi-acme; }
    location / { return 503; }
}
```

Enable this site, resolve any default-site conflict, run `nginx -t`, then reload Nginx.
Check that an absent ACME challenge returns 404 and other requests return 503.

```bash
sudo certbot certonly --webroot -w /var/www/tauapi-acme -d <domain> --agree-tos -m <email>
```

Use the supplied contact email. Verify `fullchain.pem` and `privkey.pem` under
`/etc/letsencrypt/live/<domain>/` before enabling the generated TLS site.

## Start master, initialize the site, then start slave

```bash
sudo scripts/bootstrap-stack.sh --backend-image <image-tag> --nginx maintenance
sudo scripts/set-upstream.sh master
sudo scripts/deploy-frontend.sh <release-id>
sudo python3 -I scripts/bootstrap-admin.py
sudo docker compose -p tauapi --env-file /srv/tauapi/stack/images.env -f /srv/tauapi/stack/compose.yml restart backend-master
sudo scripts/bootstrap-stack.sh --backend-image <image-tag> --with-slave --nginx maintenance
sudo scripts/set-upstream.sh both
sudo scripts/set-site-mode.sh live
sudo scripts/smoke.sh --public
```

The first bootstrap starts PostgreSQL, Redis and master. Master performs migrations.
`set-upstream.sh master` directs loopback setup requests to the running instance.
Admin initialization uses loopback HTTPS and writes credentials to
`/etc/tauapi/initial-admin.json` with mode 0600. It also disables public registration,
sets self-use mode and records the server address. Report the credential path only.
Restart master to reload setup state, then start slave. Enable live traffic after setup
and health checks pass. Check that database and Redis ports have no public host bindings.

## Install recurring operations

Install `config/systemd/tauapi-stack.service`, `tauapi-backup.service` and
`tauapi-backup.timer` into `/etc/systemd/system/`, and install `config/logrotate/tauapi-nginx`.
Run `systemctl daemon-reload`, enable Docker/Nginx/stack startup, and enable the backup timer.
Configure a certbot deploy hook to run `nginx -t && systemctl reload nginx`, then run
`certbot renew --dry-run` and check `certbot.timer`.

Run [backup and isolated restore checks](backup-and-recovery.md). Configure an off-site
backup destination separately. Run `scripts/collect-evidence.sh` to update the dated
`DEPLOYMENT_STATE.json` and English evidence summary. Add the user-facing result to
root `docs/CHANGELOG.md`.

## Existing installation migration

Copy the original application secrets before bootstrap so encrypted keys and sessions
retain the same keys. Restore the database into an empty target with backend instances
stopped, under the authorized migration procedure. If a root user already exists, omit
admin creation. Restart master, verify setup and health, then start slave and test the site.

## Failures

| Failure | Check |
| --- | --- |
| Bootstrap exit 3 | Image argument, secret file values and setup prerequisite |
| Backend unhealthy | Container logs, database/Redis health and rendered backend environment |
| TLS failure | Domain, certificate files and HTTP ACME site |
| Frontend deploy exit 8 | Deployment verification output and restored previous release |
| Lock exit 9 | Wait for the operation holding `/run/lock/tauapi-deploy.lock` |

Release and rollback commands are in [operations engineering](../engineering.md#release-commands).
