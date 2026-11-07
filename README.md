# TauAPI

TauAPI 基于 [QuantumNous/new-api](https://github.com/QuantumNous/new-api) 开发。一个仓库包含前端、纯 API 后端和运维工具，前后端独立构建、独立发布。

- [系统架构](docs/map.md)：目录分工、请求流程、构建和部署边界。
- [更新记录](docs/CHANGELOG.md)：项目变化和历史验收摘要。
- [维护规则](AGENTS.md)：共同规则；[技术索引](docs/ai/INDEX.md)按任务列出组件规范、契约和检查。

## 开发与检查

前端在 `tauapi-fe/` 使用 Bun，版本见 `package.json`。运行 `bun install --frozen-lockfile`、`bun run dev`；提交前运行相关测试、`bun run typecheck` 和 lint。

后端在 `tauapi-be/` 使用 Go，版本见各模块的 `go.mod`。运行 `make build`、`make test`。修改 RelayKit 或 TokenKit 后，进入相应目录运行 `GOWORK=off go build ./...` 和相关测试。

文档工具在根目录初始化和运行：

```sh
make docs-setup
make docs-check docs-test
make docs-impact-worktree DOCS_BASE=HEAD
```

修改文档登记表后运行 `make docs-generate`。项目检查在本地执行。

## 登录与使用

访问令牌保存在浏览器内存，刷新令牌保存在受保护的 Cookie 中。刷新页面会恢复会话，多标签页会协调刷新。
安全设置支持查看和撤销设备会话。修改密码或安全因素会使受影响的会话失效。
个人访问令牌用于按权限操作面板，API Key 用于调用模型中转接口。个人访问令牌仅在创建时显示一次。
遇到登录循环，检查网络、HTTPS、代理和 Cookie 配置。

## 运维与文档

[运维规范](tauapi-ops/docs/ai/engineering.md)集中列出发布、回滚、备份和上游同步入口；[新主机流程](tauapi-ops/docs/ai/runbooks/fresh-host.md)说明安装顺序。
后端的 `README*` 是保留的上游原文，其中的 `web/`、`electron/` 路径和相关构建步骤属于上游整仓。TauAPI 的构建方式见本页和系统架构。

项目中文说明集中在本页、`docs/map.md` 和 `docs/CHANGELOG.md`。技术规范使用英文，共同规则放在根目录，组件规则放在对应子目录。上游 README、许可证和引用资料保留原文。
