# Evidence summary (prod) — 2026-11-04T08:47:50Z

## Running services
```
backend-master  tauapi-be:53c0e999057f id=sha256:74cfee86d4c0d363c9d75108344c61b0f375e73c53acad2aa0a7eb9a51aff531 started=2026-11-04T07:59:08.646755729Z health=healthy node_type=NODE_TYPE=master
backend-slave   tauapi-be:53c0e999057f id=sha256:74cfee86d4c0d363c9d75108344c61b0f375e73c53acad2aa0a7eb9a51aff531 started=2026-11-04T07:59:18.598246664Z health=healthy node_type=NODE_TYPE=slave
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
- frontend release: fe-r1-aade206 (aade20681f96)
- backend: tauapi-be:53c0e999057f / tauapi-be:53c0e999057f
- PostgreSQL 16.15 (Debian 16.15-1.pgdg12+2), Redis 7.4.12, Nginx 1.24.0 (Ubuntu)
- certificate notAfter: Feb  2 06:22:25 2027 GMT
## Release log
```
2026-11-04T08:19:12Z deploy fe-r1-aade206 prev=none
```
## Backups / restore checks
```
tauapi-20261104T082213Z.dump
2026-11-04T08:22:21Z restore-check tauapi-20261104T082213Z.dump tables=38 users=1 root=1 setups=1 app_read=ok
```
## Timers
```
NEXT                        LEFT LAST PASSED UNIT                ACTIVATES
Wed 2026-11-04 15:47:34 UTC   6h -         - certbot.timer       certbot.service
Thu 2026-11-05 03:30:12 UTC  18h -         - tauapi-backup.timer tauapi-backup.service

```
