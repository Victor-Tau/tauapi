# TauAPI

[QuantumNous/new-api](https://github.com/QuantumNous/new-api) 的前后端分离二次开发发行版
（固定上游版本 `ba5f7367797566175a6cd97a748d430af3602a01`），以单一仓库形式便于分发。
New API / QuantumNous 的品牌、许可证和署名均已保留（见各部分的 LICENSE / NOTICE）。

| 目录 | 部分 | 构建 | 发布单元 |
| --- | --- | --- | --- |
| `tauapi-fe/` | React 19 + Rsbuild 前端（上游 `web/`），Minimalist Flat 界面 | 在 `tauapi-fe/` 内执行 `bun install --frozen-lockfile && bun run build` | 带版本号的静态包，挂载在 `/_ui/<release>/` 下 |
| `tauapi-be/` | 纯 API 的 Go 后端（上游去掉 `web/`、`electron/`） | 在 `tauapi-be/` 内执行 `go build .` | Docker 镜像 `tauapi-be:<commit12>` |
| `tauapi-ops/` | 部署、Nginx、发布/回滚、备份、QA、验收证据、交接 | shell / python 脚本 | – |

前后端仍然独立构建、测试、发布和回滚：发布脚本只用 `git archive` 导出 `main:tauapi-fe`
或 `main:tauapi-be` 作为构建上下文，任何一端的构建都读不到另一端的目录。

- 系统地图（架构、端点、文件树）：[`map.md`](map.md)
- 运维交接：[`tauapi-ops/HANDOFF.md`](tauapi-ops/HANDOFF.md)
- 本项目由 AI 自动维护，文档语言约定见 [`AGENTS.md`](AGENTS.md)
- 前端规则：[`tauapi-fe/AGENTS.md`](tauapi-fe/AGENTS.md)（先读 `tauapi-fe/UPSTREAM_ROOT_AGENTS.md`）
- 后端规则：[`tauapi-be/AGENTS.md`](tauapi-be/AGENTS.md)

分支：`main`（全部定制）；`vendor/upstream-fe`、`vendor/upstream-be`（按拆分布局保存的原始上游导入，
通过 `tauapi-ops/scripts/sync-upstream.sh` 合并进各子目录）。
