# TauAPI

TauAPI 基于 [QuantumNous/new-api](https://github.com/QuantumNous/new-api) 开发。一个仓库包含前端、纯 API 后端和运维工具，前后端独立构建、独立发布。

- [系统架构](docs/map.md)：目录分工、请求流程、构建和部署边界。
- [更新记录](docs/CHANGELOG.md)：项目变化和历史验收摘要。
- [维护规则](AGENTS.md)：共同规则；[技术索引](docs/ai/INDEX.md)按任务列出组件规范、契约和检查。

## 开发与检查

前端在 `tauapi-fe/` 使用 Bun，版本见 `package.json`。运行 `bun install --frozen-lockfile`、`bun run dev`；提交前运行相关测试、`bun run typecheck` 和 lint。

后端在 `tauapi-be/` 使用 Go，版本见各模块的 `go.mod`。运行 `make build`；测试时使用 `make test TEST_MODULE=. TEST_PACKAGES=./修改的包`，只选择新增或修改的包。RelayKit、TokenKit 分别用 `TEST_MODULE=relaykit`、`TEST_MODULE=tokenkit` 单独测试。

文档工具在根目录初始化和运行：

```sh
make docs-setup
make docs-check
# 仅在该测试模块涉及新增或修改内容时运行：
make docs-test DOCS_TEST_MODULES=docs.tools.tests.test_release_policy
make docs-impact-worktree DOCS_BASE=HEAD
```

修改文档登记表后运行 `make docs-generate`。项目检查在本地执行。
所有操作必须在现有 `main` 分支上进行，禁止创建任何分支，包括任务、功能、发布、上游导入和升级分支。测试只允许针对新增或修改的模块单独进行，严禁全量测试、未指定测试文件或包的测试命令，以及测试未修改模块。构建和发布脚本不再自动运行全量测试。

## 登录与使用

访问令牌保存在浏览器内存，刷新令牌保存在受保护的 Cookie 中。刷新页面会恢复会话，多标签页会协调刷新。
安全设置支持查看和撤销设备会话。修改密码或安全因素会使受影响的会话失效。
个人访问令牌用于按权限操作面板，API Key 用于调用模型中转接口。个人访问令牌仅在创建时显示一次。
遇到登录循环，检查网络、HTTPS、代理和 Cookie 配置。

## 运维与文档

[GitHub Releases](https://github.com/Victor-Tau/tauapi/releases) 的发布说明必须使用简体中文，只列出修改或更新内容，不添加安装部署步骤、构建测试结果或其他说明。后端可执行文件和 Docker 镜像只构建 `linux-amd64`，前端提供平台无关的静态包。禁止 SHA256 校验及 SHA256 操作，禁止生成、打包或上传 SHA256 校验文件、数值及相关校验元数据。前端包保留发布号和不可变资源路径，部署与回滚直接比较文件内容；后端包包含 `new-api`、版本清单和许可证。

使用现有运维目录更新时，将前端归档放入前端产物目录，运行 `deploy-frontend.sh <release-id>` 完成资源发布和原子切换；Docker 镜像归档先用 `gzip -dc <image.tar.gz> | docker load` 加载，再运行 `deploy-backend.sh tauapi-be:<version>` 排空连接并逐个替换实例。完整命令见运维规范。保留旧前端资源供已打开的页面使用；后端重启仍需遵守数据库兼容和备份要求。

系统更新检查默认读取本仓库的公开 Release，管理员可在维护设置中修改仓库。发布标签使用 `v<version>`，版本来自两端各自的 `VERSION`；发布包供运维更新，页面中的“检查更新”负责通知和打开 Release 页面。

[运维规范](tauapi-ops/docs/ai/engineering.md)集中列出发布、回滚、备份和上游同步入口；[新主机流程](tauapi-ops/docs/ai/runbooks/fresh-host.md)说明安装顺序。
后端的 `README*` 是保留的上游原文，其中的 `web/`、`electron/` 路径和相关构建步骤属于上游整仓。TauAPI 的构建方式见本页和系统架构。

项目中文说明集中在本页、`docs/map.md` 和 `docs/CHANGELOG.md`。技术规范使用英文，共同规则放在根目录，组件规则放在对应子目录。上游 README、许可证和引用资料保留原文。
