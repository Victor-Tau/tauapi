# HANDOFF — TauAPI (tauapi-fe / tauapi-be)，部署于 api.victor-tau.xyz

日期：2026-11-04 (UTC)。主机：Ubuntu 24.04.5，4 vCPU，3.8 GiB 内存 + 4 GiB 交换空间，单台服务器。
上游：QuantumNous/new-api `ba5f7367797566175a6cd97a748d430af3602a01`（已从 GitHub 核实）。New API / QuantumNous 的品牌标识、版权声明和模块路径保持不变（受上游规则保护）。

## 1. URL 与当前状态

- **https://api.victor-tau.xyz** 已上线（公开模式）。前端与 API 共用同一个源（origin）。
- 公网冒烟测试 `scripts/smoke.sh --public`：**42/42 通过**（页面、API、插件、静态资源、缓存头、隐藏文件、HTTP→HTTPS、TLS、登录/刷新/登出）。
- 正在运行：前端 `fe-r3-0dab41b`；后端 master + slave `tauapi-be:a4231663776e`；PostgreSQL 16.15；Redis 7.4.12；Nginx 1.24.0。

## 2. 代码仓库（单一 TauAPI monorepo）

| 项目 | 值 |
| --- | --- |
| 仓库 | `/opt/tauapi`（一个 Git 仓库；子目录 `tauapi-fe/`、`tauapi-be/`、`tauapi-ops/`，以及 `README.md`、`map.md`） |
| 远端 | `origin` → `/var/lib/tauapi/git/tauapi.git`（裸仓库，分支 `main`） |
| 分支 | `main`（所有定制内容）；`vendor/upstream-fe`、`vendor/upstream-be`（按拆分布局导入的原始上游代码） |
| 标签 | `upstream/fe-ba5f73677975`、`upstream/be-ba5f73677975`、`release/fe-r1-aade206`、`release/fe-r2-3097ff7`、`release/fe-r3-0dab41b`、`release/be-53c0e999057f`、`release/be-a4231663776e` |
| 历史 | 保留了原先三个仓库的所有提交（subtree 合并：`41da14a` fe、`dec55a4` be、`3cad3d6` ops）。在这些合并之前，文件位于旧仓库根目录，因此 `git log -- tauapi-fe/<file>` 会在合并处中断；查看更早的历史请使用该合并的第二个父提交并配合旧路径，例如 `git log 41da14a^2 -- src/styles/theme.css`（fe）、`git log dec55a4^2 -- router/main.go`（be） |
| 拆分时期的归档 | `/var/lib/tauapi/git/archive-split-20261104/tauapi-{fe,be,ops}.bundle`（已验证）；旧的裸远端 `tauapi-{fe,be,ops}.git` 保留但不再使用 |

- 前端和后端仍然是**相互独立的构建/发布单元**：`build-frontend.sh` / `build-backend.sh` 仅使用 `git archive` 导出 `main:tauapi-fe` / `main:tauapi-be`，因此任一构建都看不到另一个目录。发布 ID 带有 monorepo 的提交号。
- 分发方式：`git clone /var/lib/tauapi/git/tauapi.git` 或 `git -C /opt/tauapi bundle create tauapi.bundle --all`。
- 只读上游缓存：`/var/cache/tauapi/upstream`。提交身份：`TauAPI Maintainer <tauapi-maintainer@localhost>`（仅限本仓库）。
- 未配置任何外部远端；没有向 GitHub 或上游推送任何内容。添加方法：`git -C /opt/tauapi remote add github <url> && git push github main vendor/upstream-fe vendor/upstream-be --tags`。
- 每次备份都会写入 `/var/backups/tauapi/git/tauapi-<time>.bundle`。

## 3. 发布产物

| 单元 | 发布 | 标识 |
| --- | --- | --- |
| 前端（当前） | fe-r3-0dab41b | 提交 0dab41b8b090…，tar.gz sha256 `269fb7fcc3573b814e94b05057c16b1d17767dabba20bf9790db8770067b1d7c`，静态资源 `/_ui/fe-r3-0dab41b/` |
| 前端（回滚目标） | fe-r2-3097ff7 | sha256 `fa75539cb1082b4417560e11c0c11099a93b2299a0d7b512db385e9830990058` |
| 前端（Flat 之前） | fe-r1-aade206 | sha256 `33529454fd418d45ec9967fe10cd6f0fbce583e4b3d78f75d00603477d0ee9a3` |
| 后端（当前） | tauapi-be:a4231663776e | 镜像 `sha256:d5d09addfebb6395923d3443ea3a26430fc2e33891dfd177007bf8b650df8639`，版本 `0.0.0+be.a4231663776e` |
| 后端（回滚目标） | tauapi-be:53c0e999057f | 镜像 `sha256:74cfee86d4c0d363c9d75108344c61b0f375e73c53acad2aa0a7eb9a51aff531` |
| PostgreSQL | postgres:16-bookworm@sha256:e8a07d2c…bd938 | 16.15 |
| Redis | redis:7.4-bookworm@sha256:b6b6e3dc…882f5 | 7.4.12 |

后端镜像为本地构建（无镜像仓库），因此没有仓库摘要（digest）；它们通过镜像 ID 加 `org.opencontainers.image.revision` 标签来标识。构建器和运行时基础镜像在 Dockerfile 中均按 digest 固定。上表中的已部署版本构建时 `VERSION` 为空，因此显示为 `0.0.0+be.<commit>` / `0.0.0+fe.<commit>`。从 2026-11-04 起 `tauapi-fe/VERSION`、`tauapi-be/VERSION` 记录 TauAPI 自己的语义化版本（当前 `1.0.0`），下次构建后显示为 `1.0.0+fe.<commit>` / `1.0.0+be.<commit>`。

## 4. Minimalist Flat

该设计已应用于所有自有（first-party）UI。参见 `evidence/UI_REVIEW.md`（范围、改动内容、已检查的截图）和 `UI_INVENTORY.csv`（77 个路由/板块，每项均有浅色/深色/移动端结论及证据路径）。

- 测试：2465/2465 通过。对比度：16/16 通过。浮层：17/17。矩阵：230/231 次截图。
- 唯一一次未截取到的情况：移动端无效 OAuth 回调在截图前会重定向到登录页，这是预期行为。
- 后续工作的实现规则：`docs/MINIMALIST_FLAT.md`。

## 5. 管理员

- 用户名：**admin**。
- 密码仅保存在仅 root 可读的文件 **`/etc/tauapi/initial-admin.json`** 中（权限 0600）。密码不会在任何地方打印出来。
- 在服务器上读取：`sudo jq -r .password /etc/tauapi/initial-admin.json`。然后在 https://api.victor-tau.xyz/sign-in 登录并修改密码（Security & Access）。
- 公开注册**已关闭**，自用模式已开启，演示模式已关闭。

## 6. 拓扑、端口、数据、密钥

```
Internet ─▶ Nginx :80 (ACME + 301) / :443 (TLS, /etc/nginx/sites-available/tauapi.conf)
   ├─ registered SPA pages ─▶ /srv/tauapi/current/frontend/index.html   (no-store)
   ├─ /_ui/<release>/…     ─▶ /srv/tauapi/public/_ui/<release>/          (immutable; 404 if missing)
   ├─ /_meta/ui-version.json
   └─ everything else      ─▶ upstream tauapi_backend
                               ├─ backend-master 127.0.0.1:3001 (NODE_TYPE=master, migrations)
                               └─ backend-slave  127.0.0.1:3002 (NODE_TYPE=slave)
                                   └─ internal network: postgres:5432, redis:6379 (no host ports)
```

- Compose 项目 `tauapi`：`/srv/tauapi/stack/compose.yml` 和 `images.env`，二者均由 `tauapi-ops/templates/compose.yml` 渲染生成。
- 数据卷：`tauapi_pgdata`、`tauapi_redisdata`、`tauapi_master_data`、`tauapi_slave_data`。
- 密钥，均位于 `/etc/tauapi/`，仅 root 可读、权限 0600：`postgres.env`、`redis.env`、`app-secrets.env`（SESSION_SECRET、CRYPTO_SECRET）、`backend.env`（由其他文件派生）、`initial-admin.json`。它们只生成一次，永不重新生成。
- Nginx 包含的文件：
  - `/etc/nginx/tauapi/upstream-backend.conf`（当前生效的集合）、`proxy-backend.conf`、`security-headers.conf`
  - `/etc/nginx/conf.d/tauapi-common.conf`
  - `/etc/nginx/modules-enabled/90-tauapi-main.conf`（`worker_shutdown_timeout 660s`）
- 防火墙：UFW 保持未启用，SSH 未改动。云安全组未检查（无账号访问权限）。只有 22、80 和 443 对公网监听。

## 7. 发布命令（所有脚本位于 /opt/tauapi/tauapi-ops/scripts；脚本自行获取部署锁）

```bash
# Frontend
scripts/build-frontend.sh --rev main --release-id fe-r4-<short>     # as tau; typecheck+test unless --skip-checks
sudo scripts/deploy-frontend.sh fe-r4-<short>                        # validate, publish /_ui, atomic switch, verify, auto-restore on failure, tag
sudo scripts/rollback-frontend.sh [<release-id>]                     # no rebuild; default = previous release
sudo scripts/prune-frontend.sh [--apply]                             # keeps newest 5 + <30 days + current + rollback target

# Backend
scripts/build-backend.sh --rev main                                  # git-archive context, prints IMAGE_TAG
sudo scripts/deploy-backend.sh tauapi-be:<commit12>                  # backup, master then slave, drained, verified, tagged
sudo scripts/rollback-backend.sh                                     # same procedure back to the recorded previous image

# Checks / ops
sudo scripts/smoke.sh --public
sudo scripts/backup.sh --reason manual ; sudo scripts/restore-check.sh
sudo scripts/collect-evidence.sh                                    # refresh DEPLOYMENT_STATE.json + evidence/SUMMARY-prod.md
scripts/preflight.sh ; scripts/verify-independent-builds.sh all
sudo scripts/set-site-mode.sh maintenance|live                       # maintenance = ACME + loopback only
```

`deploy-backend.sh` 返回退出码 10，表示该实例在排空窗口结束后仍持有长连接。脚本**没有**停止它。请稍后重新运行，或使用 `sudo scripts/set-upstream.sh both` 恢复流量。

## 8. 上游同步

- 运行 `scripts/sync-upstream.sh <sha|tag>`。它会导入到 `vendor/upstream-fe` / `vendor/upstream-be`（重复运行不会产生变化），从 main 创建 `upgrade/<short-sha>`，并将其 subtree 合并到 `tauapi-fe/` 和 `tauapi-be/`。它从不改写 main，也从不部署任何内容。
- 合并到 main 之前的检查关卡：
  - 后端：`go build .`、`go test ./...`，以及 relaykit 和 tokenkit；
  - 前端：安装、类型检查、测试、构建；
  - fixture sha256 比对（`UPSTREAM.json`）；
  - schema、认证和插件审查；
  - 如果 `src/routes` 有变化，则刷新 `ROUTE_CONTRACT.json`。
- 没有任何定时器会自动拉取上游。
- 上游合并时如果 `VERSION` 冲突，始终保留我们自己的版本号（上游版本只记录在 `UPSTREAM.json` / `UPSTREAM_LOCK.json`）。

## 8.1 系统更新检查（TauAPI 自己的 Releases）

管理员看到的"系统更新"会在浏览器端请求 `https://api.github.com/repos/<仓库>/releases`（每小时一次），不再查询官方 QuantumNous/new-api。

- 目标仓库可在 **系统设置 → 运维 → 系统维护 →"更新源仓库"** 中手动指定，可以填 `owner/repo` 或 `https://github.com/owner/repo`，保存后立即生效（后端选项 `SystemUpdateRepository`，通过 `/api/status` 的 `system_update_repository` 下发）。
- 留空时默认使用 `Victor-Tau/tauapi`。
- 目标仓库必须是**公开的**，否则会显示检查失败。

发布新版本的步骤：
1. 同时修改 `tauapi-fe/VERSION` 和 `tauapi-be/VERSION`（如 `1.1.0`），提交到 main。
2. 按第 7 节构建并部署。
3. 打 tag `v1.1.0`，推送到 `github` remote，在 GitHub 上基于该 tag 发布 Release（不要保持草稿；预发布用 `v1.1.0-rc.1`）。

版本比较规则：tag 必须形如 `v主.次.修订[-alpha|beta|rc|patch[.N]]`，其他 tag（例如 `release/*`、`upstream/*`）会被忽略；比较对象是后端 `/api/status` 返回的版本号。

## 9. TLS、日志、备份、恢复

- **TLS：** certbot 2.9 (apt)，webroot 为 `/var/www/tauapi-acme`，账号注册时未使用邮箱（未提供）。`certbot.timer` 已启用，`renew --dry-run` 通过。部署钩子运行 `nginx -t && systemctl reload nginx`。到期日期 2027-02-02。
- **日志：**
  - Nginx：`/var/log/nginx/tauapi.{access,error}.log` 只记录路径（不含查询字符串、cookie 或认证头）；每日轮转，保留 14 份。
  - Docker json-file 日志：每个容器 20 MB × 5。
- **备份：**
  - `tauapi-backup.timer` 每天 03:30 UTC 运行：`pg_dump -Fc` 加 git bundle 加清单，保留 7 份每日 + 4 份每周。
  - `deploy-backend.sh` 在每次发布前也会进行一次备份。
  - **仅限本地**（`/var/backups/tauapi`）：没有异地副本，因此一旦丢失这台主机，代码历史和数据会同时丢失。
- **恢复演练**（`restore-check.sh`，将最新转储导入隔离的 tmpfs PostgreSQL）：38 张表，root 用户和 setup 行存在，且后端镜像可以读取恢复后的数据库。生产数据库从不会被自动覆盖。

## 10. 证据与外部集成

- 证据文件：
  - `evidence/ACCEPTANCE.md`：逐条对照 GOAL §19；
  - `evidence/RELEASE_DRILLS.md`、`evidence/UI_REVIEW.md`、`evidence/ui/CONTRAST.md`；
  - `evidence/SUMMARY-prod.md`、`evidence/P0-preflight.md`、`DEPLOYMENT_STATE.json`。
- 原始日志和截图保存在本地（已被 git 忽略），位于 `evidence/raw/` 下。
- **未配置 / 未使用真实提供商验证：**
  - 模型提供商：没有 API 密钥，也没有生产渠道。中继、SSE 和 WS 仅在隔离 QA 栈中针对内部 **mock** 上游进行过验证；没有发起过任何真实的模型调用。
  - SMTP：未配置，因此密码重置和验证邮件未经验证（页面可以正常渲染）。
  - OAuth / OIDC / WeChat / Telegram / Passkey RP：未配置（回调页面可渲染并能处理失败情况）。
  - 支付（Stripe、epay、Creem、Waffo）：未配置。没有创建任何订单。
  - 分析（Umami / GA）：未启用。
  - Uptime Kuma、Worker 代理：未配置。

## 11. 阻塞项、安全状态、后续步骤

- 没有阻塞性问题。站点已上线，所有核心关卡均已通过。
- **NTP：** timesyncd 处于活动状态，但没有从 ntp.ubuntu.com 收到任何数据包（出站 UDP 123 似乎被服务商过滤）。时钟目前与公网 HTTPS 的 `Date` 头相差在 1 秒以内。如果你可以控制云防火墙，请放行出站 UDP 123，或将 timesyncd 指向一个可达的 NTP 服务器。
- **异地备份：** 请提供一个目标（另一台主机，或带凭据的对象存储）以实现灾难恢复。
- **可选清理**（有意保持未动）：
  - Docker 卷 `newapi_*`，来自 TauAPI 重命名之前的首次引导运行。它们只包含一个初始管理员，没有用户数据。删除方法：`sudo docker volume rm newapi_pgdata newapi_redisdata newapi_master_data newapi_slave_data`。
  - QA 卷 `tauapi-qa_*` 和 `/etc/tauapi-qa`：QA 已停止，其 Nginx 站点已禁用。重新启动方法：`sudo TAUAPI_ENV=qa scripts/bootstrap-stack.sh --with-slave --nginx live`（同时会重新启用回环站点）。
- **Sudo 密码：** 你分享的密码在工作期间缓存于 `~tau/.config/tauapi-sudo/`（0600），并已在**交接时删除**。该密码曾出现在聊天中，建议考虑修改。

## 12. 能力限制

- 单台服务器，因此无法抵御主机故障，不具备高可用。master/slave 组合仅用于消除发布期间单个实例的停机时间。
- **新请求**可无错误地在实例间切换（在 5 次滚动发布中约 280 个探测请求，失败 0 个）。
- 在排空窗口内结束的**有限时长 SSE** 流可正常完成。
- **长连接 WebSocket** 不会迁移：
  - 仍持有长连接的实例不会被停止（退出码 10），由运维人员决定；
  - 客户端之后会重新连接；
  - 不承诺会话恢复。
- 每个后端实例的内存上限为 900 MB；每个实例的 SQL 连接池上限为 25 个打开连接 / 5 个空闲连接。
