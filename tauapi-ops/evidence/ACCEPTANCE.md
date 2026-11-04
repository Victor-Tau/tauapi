# GOAL §19 验收清单 — 真实状态(2026-11-04)

图例:✅ 已验证(附证据链接) · ⚠️ 已完成但有所述限制 · ⛔ 未完成

## A. 仓库与构建
| 项目 | 状态 | 证据 |
| --- | --- | --- |
| 前端/后端位于不同目录,git-common-dir 不同 | ⚠️ 已被取代 | 交付期间已验证为独立仓库;2026-11-04 应用户要求合并为单一 monorepo `/opt/tauapi`(DECISIONS 19)。构建/发布独立性通过 `git archive main:<subdir>` 得以保留 |
| 父目录不是仓库 | ⚠️ 已被取代 | `/opt/tauapi` 现为 monorepo(用户要求) |
| 源码提交、自定义提交、发布标签、已验证的 bundle | ✅ | `vendor/upstream` + `main`,标签 `upstream/ba5f73677975`、`release/fe-r1/r2/r3`、`release/be-53c0e999057f`、`release/be-a4231663776e`;bundle `/var/backups/tauapi/git/*.bundle` 已验证 |
| 工作树干净,git 中无密钥/DB/缓存 | ✅ | 三者 `git status` 均干净;密钥模式扫描仅匹配生成器代码;`evidence/raw` 被 git 忽略 |
| 前端构建无需 Go/兄弟仓库 | ✅ | `scripts/verify-independent-builds.sh fe`:单独克隆,PATH 中无 Go → install/typecheck/test(2465 通过)/build 正常,0 个跨仓库引用,dist 中 0 个后端文件 |
| 后端构建无需 web/、Bun/Node、占位 HTML | ✅ | 在 `golang:1.26.10-alpine@sha256:9ce2…` 内干净克隆(无 node/bun/npm):`go build .` 正常,根目录 47 个包 ok / 0 FAIL,relaykit 9 ok,tokenkit ok;无 `index.html` |
| 共享夹具可追溯,插件保留 | ✅ | `testdata/contracts/frontend_simulation.json` sha256 `1569342e…35e3` = 后端 `pkg/billingexpr/testdata` = `UPSTREAM.json`;`plugins/tasks/*.js` 保留 |
| 上游同步不会覆盖 main | ✅ | 针对固定 SHA 重新运行 `sync-upstream.sh`:导入无操作,`upgrade/<sha>` 合并,main 与 vendor/upstream 未变 |

## B. UI
| 项目 | 状态 | 证据 |
| --- | --- | --- |
| 所有第一方路由和动态 section 均在矩阵中 | ✅ | `UI_INVENTORY.csv` 77 行(路由树 + 11 个 section 注册表 + 认证/错误/安装) |
| 共享的控件/布局/对话框/表格/图表/代码已统一 | ✅ | `evidence/UI_REVIEW.md` |
| 首页、用户控制台、所有管理设置均为扁平风格 | ✅ | 矩阵截图 230/231 通过;浮层 17/17 |
| 深色/浅色、偏好设置、i18n、数字格式化 | ✅ | 两种主题均有令牌;预设/字体/密度/圆角保留;7 种语言;测试 2465 通过;格式化代码未改动 |
| 移动端交互和主要页面布局 | ✅ | 390×844 截图,移动端侧边栏面板,移动端菜单,卡片列表回退 |
| 键盘、焦点、对比度 | ✅ | `evidence/ui/CONTRAST.md` 16/16;键盘检查(Tab 顺序、焦点环、Enter、Escape + 焦点返回、Ctrl+K) |
| 无被移除的功能 / 虚假 UI / 仅靠全局 CSS | ✅ | 173 个文件的源码变更,测试数量不变,无全局 `!important` 覆盖 |
| 截图确实经过评审 | ✅ | 列表见 `evidence/UI_REVIEW.md` |

## C. 部署与认证
| 项目 | 状态 | 证据 |
| --- | --- | --- |
| 有效的公网证书 | ✅ | Let's Encrypt (YE2),CN api.victor-tau.xyz,notAfter 2027-02-02;从公网 IP 冒烟 `ssl_verify_result=0` |
| HTTP 重定向、ACME 例外、续期演练 | ✅ | 301 保留路径+查询串;ACME 路径由 `/var/www/tauapi-acme` 提供;`certbot renew --dry-run` 成功;`certbot.timer` 已激活;部署钩子 `nginx -t && reload` |
| 未初始化的服务绝不公开 | ✅ | 在管理员初始化之前使用维护闸门(真实源 IP);即使伪造 `X-Forwarded-For`,公网仍返回 503 |
| 已创建管理员、公网地址、凭据安全 | ✅ | `admin`,`/etc/tauapi/initial-admin.json`(root 0600);`ServerAddress=https://api.victor-tau.xyz` |
| 自用、非演示、关闭注册 | ✅ | `/api/status`:self_use_mode_enabled=true,demo_site_enabled=false,register_enabled=false |
| Secure cookie / 可信 URL / 代理 | ✅ | `SESSION_COOKIE_SECURE=true`,`SESSION_COOKIE_TRUSTED_URL=https://api.victor-tau.xyz`,`TRUSTED_PROXIES=172.30.70.1/32`;会话 IP 记录为真实客户端,而非网桥 |
| 登录/刷新/登出以及重启后的会话 | ✅ | 公网 `smoke-auth.py`:错误密码被拒绝,Secure+HttpOnly 刷新 cookie,刷新需要 Origin,轮换,登出,登出后刷新 401;QA:重启两个后端后会话刷新正常 |
| DB/Redis/后端端口不对公网开放 | ✅ | 监听:22、80、443 对公网;3001/3002 在 127.0.0.1;无 5432/6379 主机端口 |
| 恰好一个主节点 + 一个从属节点,密钥/DB 相同 | ✅ | `DEPLOYMENT_STATE.json`、`SUMMARY-prod.md` |

## D. 路由与发布
| 项目 | 状态 | 证据 |
| --- | --- | --- |
| SPA 深层链接和 /oauth 页面 | ✅ | 冒烟 16 项页面检查,含 `/oauth/github`、`/user/reset`、旧版 `/login`、`/console/token` |
| /api、/v1、/v1beta、/pg、MJ、插件路径指向后端 | ✅ | 冒烟:全部返回 JSON 响应;插件 `/ali/...`、`/tasks`、`/suno/fetch` 到达调度器 |
| /dashboard/billing 优先于 dashboard 页面 | ✅ | `/dashboard/billing/usage` → 401 JSON |
| 未知 API 不返回 HTML 200;缺失资源返回 404 | ✅ | `/api/__nope__` 404 JSON;缺失的 `/_ui/...js` 404,不缓存 |
| SSE 即时、WS 升级 + 排空边界 | ✅ | `evidence/RELEASE_DRILLS.md`(经 Nginx 每秒 1 个分块;101;超出窗口的 WS → 发布暂停,不强杀) |
| 前端发布/回滚无需重启后端 | ✅ | 每次前端部署/回滚前后容器 ID/启动时间均相同 |
| 后端滚动/回滚无需重新构建前端 | ✅ | 每次后端运行均为 `frontend_current_unchanged=true` |
| 旧标签页懒加载旧分块 | ✅ | fe-r2 上线后 fe-r1 的分块 7/7 |
| 版本、SHA、摘要、资源哈希可追溯 | ✅ | `DEPLOYMENT_STATE.json`、发布清单、标签 |
| 失败的发布可恢复;DB 恢复 ≠ 镜像回滚 | ✅ | 观察到前端自动恢复;排空未完成退出码 10;schema 变更后 rollback-backend 拒绝执行;恢复是单独的隔离检查 |

## E. 运维
| 项目 | 状态 | 证据 |
| --- | --- | --- |
| 卷、日志轮转、开机单元、续期、备份计划 | ✅ | 命名卷 `tauapi_*`;Docker json-file 20m×5;`/etc/logrotate.d/tauapi-nginx`;`tauapi-stack.service` + docker/nginx 已启用;`tauapi-backup.timer` 每日 03:30 |
| 备份已恢复到隔离的临时 DB | ✅ | `restore-check.sh`:38 张表,root 用户,setup 行,应用读取 OK |
| 已说明本地与异地备份 | ⚠️ | **仅本地**(`/var/backups/tauapi`);未配置异地目标 → 主机丢失时无灾难恢复 |
| 日志/截图/git/报告中无密钥 | ✅ | 已脱敏的访问日志格式(仅路径);collect-evidence 密钥防护;截图使用 QA 数据 |
| 已列出未配置的外部集成 | ✅ | HANDOFF.md §10 |
| 无虚假结果 / 未验证声明 / 占位符 | ✅ | 模拟上游结果标注为仅限 QA;渲染后的 env 中无 CHANGE_ME 值 |

已知限制:NTP(出站 UDP 123 似乎被过滤;时钟与公网 HTTPS Date 头相差在 1 秒以内)、上游 lint 基线(152 个错误)、单主机(无高可用)。
