# 发布演练(真实运行,2026-11-04 UTC)

原始日志:`evidence/raw/drill-*`(已被 git 忽略)。脚本:`scripts/deploy-*.sh`、`scripts/rollback-*.sh`、`qa/release-drill.sh`。
QA = 隔离栈(`TAUAPI_ENV=qa`,独立 DB/Redis,回环 :8443,真实证书,模拟上游)。生产 = api.victor-tau.xyz。

## 使用的制品(真实、互不相同、相互兼容)

| 单元 | A | B | C |
| --- | --- | --- | --- |
| 前端 | `fe-r1-aade206`(Flat 之前,sha256 `33529454…3a6`) | `fe-r2-3097ff7`(Minimalist Flat,`fa75539c…0058`) | `fe-r3-0dab41b`(无障碍 + 发布提示,`269fb7fc…1d7c`) |
| 后端 | `tauapi-be:53c0e999057f`(`sha256:74cfee86…f531`,be-r1) | `tauapi-be:a4231663776e`(`sha256:d5d09add…8639`,be-r2,新提交 + 新版本字符串) | – |

## 前端

| 演练 | 环境 | 结果 |
| --- | --- | --- |
| 部署 fe-r1 → current | 生产、QA | 资源发布到 `/_ui/fe-r1-aade206/`,原子符号链接切换,线上验证通过,后端容器 ID/启动时间未变 |
| 部署 fe-r2 | 生产、QA | 同上;`release/fe-r2-3097ff7` 标签 |
| 回滚 fe-r2 → fe-r1(不重新构建) | 生产、QA | `rollback-frontend.sh` 复用已发布的制品;`/_meta/ui-version.json` = fe-r1;后端未变 |
| 重新部署 fe-r2 | 生产 | "versioned assets already published (identical)" – 不可变性检查,未覆盖 |
| 部署 fe-r3 | 生产、QA | current = fe-r3;公网冒烟 42/42 |
| 验证失败 → 自动恢复 | QA | 一次运行遇到 SPA 重定向循环(从属节点过期,见 DECISIONS 17);`deploy-frontend.sh` 自动恢复了上一个发布版本(发布日志中为 `deploy-failed`) |
| 旧标签页懒加载分块 | QA | 标签页在 fe-r1 上打开;fe-r2 设为 current 后,客户端导航从 `/_ui/fe-r1-aade206/` 加载了 **7 个懒加载分块,0 次失败**,无整页重新加载 |
| 新版本提示 | QA | 标签页在 fe-r3 上,线上切换后;显示带"刷新"操作的提示,**0 次自动重新加载**,搜索框中键入的文字被保留 |

## 后端滚动发布(排空,一次一个实例)

顺序:主节点移出上游 → 排空(Nginx→后端已建立连接 = 0)→ 替换 → 验证(容器镜像 ID、`/api/status`、基于 DB 的 `/api/setup.status`、`server_address`、JSON 404)→ 重新加入 → 从属节点同样处理。

| 演练 | 环境 | 排空 | 新请求探测(每 0.2 秒) | 发布期间的流 |
| --- | --- | --- | --- | --- |
| be-r1 → be-r2 | QA | 主节点 15 秒(等待在途 SSE),从属节点 2 秒 | 107 成功 / **0 失败** | SSE `mock-slow-20`:20 个分块,位于 1.08 秒 … 20.09 秒,`[DONE]` 在 20.11 秒(在被排空的实例上,未被切断)。WS:101,20 秒内 22 个事件,客户端正常关闭 |
| be-r2 → be-r1(回滚) | QA | 主节点 17 秒,从属节点 2 秒 | – | SSE 20/20 + `[DONE]`;WS 22 个事件,正常关闭 |
| be-r1 → be-r2 | 生产 | 2 秒 / 2 秒 | 59 成功 / **0 失败** | (生产无测试密钥;仅探测) |
| be-r2 → be-r1(回滚) | 生产 | 2 秒 / 2 秒 | 54 成功 / **0 失败** | – |
| be-r1 → be-r2(最终) | 生产 | 2 秒 / 2 秒 | 57 成功 / **0 失败** | – |

每次运行之后:目标镜像上恰好有一个主节点和一个从属节点;前端 `current` 未变;已记录 `release/be-<commit>` 标签。

## 长连接边界(WS 长于排空窗口)

QA,`--ws 150 --drain 30`:主节点被移出上游,150 秒的 WebSocket 使其在 30 秒内保持 1 个连接 → `deploy-backend.sh` **以 10 退出,"drain incomplete … NOT stopping it"**,记录了 `backend-release-paused.json`,主节点保持运行(仅服务其已有连接),从属节点服务所有新流量。该 WS 跑满了 150 秒(152 个事件,正常关闭)。随后操作员恢复了上游(`set-upstream.sh both`)。没有任何东西被强制终止。

能力说明:
- 新请求在实例间切换,没有失败请求(见上文实测)。
- 在排空窗口内结束的有界 SSE 流可正常完成。
- 长连接 WebSocket **不会被迁移**:Go 的 `Shutdown` 不会等待被劫持(hijacked)的连接,因此脚本拒绝停止仍持有这些连接的实例并给出报告。存活时间超过窗口的 WS 的客户端必须在操作员完成发布后重新连接;不承诺会话恢复。
- Nginx `worker_shutdown_timeout 660s` 限定了重新加载后旧 worker 保持连接的时长(长于后端的 120 秒关闭窗口)。

## 数据

- 发布前备份由 `deploy-backend.sh` 自动执行(pg_dump -Fc)。
- `restore-check.sh` 将最新的生产转储恢复到内部网络上的一次性 tmpfs PostgreSQL 中:38 张表,1 个 root 用户,存在 setup 行,且后端镜像读取了恢复后的 DB(`setup.status=true`,`server_address=https://api.victor-tau.xyz`)。
- be-r1 与 be-r2 之间无 schema 变更 → 回滚是对称的。数据库恢复被记录为一项独立的、非自动的操作。
