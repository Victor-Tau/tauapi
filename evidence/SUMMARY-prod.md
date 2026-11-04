# Evidence summary (prod) — 2026-11-04T12:36:12Z

## Running services
```
backend-master  tauapi-be:a4231663776e id=sha256:d5d09addfebb6395923d3443ea3a26430fc2e33891dfd177007bf8b650df8639 started=2026-11-04T10:23:14.855520975Z health=healthy node_type=NODE_TYPE=master
backend-slave   tauapi-be:a4231663776e id=sha256:d5d09addfebb6395923d3443ea3a26430fc2e33891dfd177007bf8b650df8639 started=2026-11-04T10:23:22.11151566Z health=healthy node_type=NODE_TYPE=slave
postgres        postgres:16-bookworm@sha256:e8a07d2c7579b038938cdba6c539e580e5001caf9ea203d397b5cc83e76bd938 id=sha256:e8a07d2c7579b038938cdba6c539e580e5001caf9ea203d397b5cc83e76bd938 started=2026-11-04T07:58:49.263445146Z health=healthy node_type=
redis           redis:7.4-bookworm@sha256:b6b6e3dc0c0952737748e55d5d885272840c7e42ba41ab1d5489f693419882f5 id=sha256:b6b6e3dc0c0952737748e55d5d885272840c7e42ba41ab1d5489f693419882f5 started=2026-11-04T07:58:49.062138786Z health=healthy node_type=
```
## Listening sockets (public exposure check)
```
0.0.0.0:22
0.0.0.0:443
0.0.0.0:80
127.0.0.1:3001
127.0.0.1:3002
127.0.0.1:3101
127.0.0.1:3102
127.0.0.1:37061
127.0.0.1:45511
127.0.0.1:8443
127.0.0.53%lo:53
127.0.0.54:53
[::]:22
[::]:443
[::]:80
```
## Versions
- frontend release: fe-r3-0dab41b (0dab41b8b090)
- backend: tauapi-be:a4231663776e / tauapi-be:a4231663776e
- PostgreSQL 16.15 (Debian 16.15-1.pgdg12+2), Redis 7.4.12, Nginx 1.24.0 (Ubuntu)
- certificate notAfter: Feb  2 06:22:25 2027 GMT
## Release log
```
2026-11-04T08:19:12Z deploy fe-r1-aade206 prev=none
2026-11-04T10:22:09Z deploy fe-r2-3097ff7 prev=fe-r1-aade206
2026-11-04T10:22:12Z rollback fe-r1-aade206 prev=fe-r2-3097ff7
2026-11-04T10:22:16Z deploy fe-r2-3097ff7 prev=fe-r1-aade206
2026-11-04T11:59:22Z deploy fe-r3-0dab41b prev=fe-r2-3097ff7
2026-11-04T10:22:47Z deploy tauapi-be:a4231663776e prev=tauapi-be:53c0e999057f
2026-11-04T10:23:05Z rollback tauapi-be:53c0e999057f prev=tauapi-be:a4231663776e
2026-11-04T10:23:25Z deploy tauapi-be:a4231663776e prev=tauapi-be:53c0e999057f
```
## Backups / restore checks
```
tauapi-20261104T113835Z.dump
2026-11-04T08:22:21Z restore-check tauapi-20261104T082213Z.dump tables=38 users=1 root=1 setups=1 app_read=ok
2026-11-04T11:39:31Z restore-check tauapi-20261104T113835Z.dump tables=38 users=1 root=1 setups=1 app_read=ok
```
## Timers
```
NEXT                            LEFT LAST PASSED UNIT                ACTIVATES
Wed 2026-11-04 16:36:00 UTC 3h 59min -         - certbot.timer       certbot.service
Thu 2026-11-05 03:35:45 UTC      14h -         - tauapi-backup.timer tauapi-backup.service

```
