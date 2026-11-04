# 证据摘要（prod） — 2026-11-04T17:17:02Z

## 运行中的服务
```
backend-master  tauapi-be:db3916f928c8 id=sha256:c1ac2e161a8cb433a84b6b523b1fde1832dc697488f31e5a34e7aaff98835b96 started=2026-11-04T17:16:05.731758995Z health=healthy node_type=NODE_TYPE=master
backend-slave   tauapi-be:db3916f928c8 id=sha256:c1ac2e161a8cb433a84b6b523b1fde1832dc697488f31e5a34e7aaff98835b96 started=2026-11-04T17:16:15.622434941Z health=healthy node_type=NODE_TYPE=slave
postgres        postgres:16-bookworm@sha256:e8a07d2c7579b038938cdba6c539e580e5001caf9ea203d397b5cc83e76bd938 id=sha256:e8a07d2c7579b038938cdba6c539e580e5001caf9ea203d397b5cc83e76bd938 started=2026-11-04T07:58:49.263445146Z health=healthy node_type=
redis           redis:7.4-bookworm@sha256:b6b6e3dc0c0952737748e55d5d885272840c7e42ba41ab1d5489f693419882f5 id=sha256:b6b6e3dc0c0952737748e55d5d885272840c7e42ba41ab1d5489f693419882f5 started=2026-11-04T07:58:49.062138786Z health=healthy node_type=
```
## 监听端口（公网暴露检查）
```
0.0.0.0:22
0.0.0.0:443
0.0.0.0:80
127.0.0.1:3001
127.0.0.1:3002
127.0.0.1:37061
127.0.0.1:45511
127.0.0.53%lo:53
127.0.0.54:53
[::]:22
[::]:443
[::]:80
```
## 版本
- frontend release: fe-r4-db3916f (db3916f928c8)
- backend: tauapi-be:db3916f928c8 / tauapi-be:db3916f928c8
- PostgreSQL 16.15 (Debian 16.15-1.pgdg12+2), Redis 7.4.12, Nginx 1.24.0 (Ubuntu)
- certificate notAfter: Feb  2 06:22:25 2027 GMT
## 发布日志
```
2026-11-04T08:19:12Z deploy fe-r1-aade206 prev=none
2026-11-04T10:22:09Z deploy fe-r2-3097ff7 prev=fe-r1-aade206
2026-11-04T10:22:12Z rollback fe-r1-aade206 prev=fe-r2-3097ff7
2026-11-04T10:22:16Z deploy fe-r2-3097ff7 prev=fe-r1-aade206
2026-11-04T11:59:22Z deploy fe-r3-0dab41b prev=fe-r2-3097ff7
2026-11-04T17:16:35Z deploy fe-r4-db3916f prev=fe-r3-0dab41b
2026-11-04T10:22:47Z deploy tauapi-be:a4231663776e prev=tauapi-be:53c0e999057f
2026-11-04T10:23:05Z rollback tauapi-be:53c0e999057f prev=tauapi-be:a4231663776e
2026-11-04T10:23:25Z deploy tauapi-be:a4231663776e prev=tauapi-be:53c0e999057f
2026-11-04T17:16:19Z deploy tauapi-be:db3916f928c8 prev=tauapi-be:a4231663776e
```
## 备份 / 恢复检查
```
tauapi-20261104T171600Z.dump
2026-11-04T08:22:21Z restore-check tauapi-20261104T082213Z.dump tables=38 users=1 root=1 setups=1 app_read=ok
2026-11-04T11:39:31Z restore-check tauapi-20261104T113835Z.dump tables=38 users=1 root=1 setups=1 app_read=ok
```
## 定时器
```
NEXT                        LEFT LAST                           PASSED UNIT                ACTIVATES
Thu 2026-11-05 03:35:45 UTC  10h -                                   - tauapi-backup.timer tauapi-backup.service
Thu 2026-11-05 11:04:14 UTC  17h Wed 2026-11-04 16:36:33 UTC 40min ago certbot.timer       certbot.service

```
