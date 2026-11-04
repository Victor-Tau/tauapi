# TauAPI

## 目录结构

| 目录 | 内容 | 构建命令 | 发布单元 |
| --- | --- | --- | --- |
| `tauapi-fe/` | React 19 + Rsbuild 前端（上游 `web/`），Minimalist Flat 界面 | `bun install --frozen-lockfile && bun run build` | 带版本号的静态包，挂载在 `/_ui/<release>/` |
| `tauapi-be/` | 纯 API 的 Go 后端（上游去掉 `web/`、`electron/`） | `go build .` | Docker 镜像 `tauapi-be:<commit12>` |
| `tauapi-ops/` | 部署、Nginx、发布/回滚、备份、QA、验收证据、交接 | shell / python 脚本 | – |

构建命令均在对应子目录内执行。

## 独立构建与发布

前后端仍然独立构建、测试、发布和回滚：发布脚本只用 `git archive` 导出 `main:tauapi-fe` 或 `main:tauapi-be` 作为构建上下文，任何一端的构建都读不到另一端的目录。

## 分支

| 分支 | 用途 |
| --- | --- |
| `main` | 全部定制代码 |
| `vendor/upstream-fe` | 前端的原始上游导入（拆分布局） |
| `vendor/upstream-be` | 后端的原始上游导入（拆分布局） |

上游导入通过 `tauapi-ops/scripts/sync-upstream.sh` 合并进各子目录。

## 文档导航

| 文档 | 说明 |
| --- | --- |
| [`map.md`](map.md) | 系统地图：架构、端点、文件树 |
| [`tauapi-ops/HANDOFF.md`](tauapi-ops/HANDOFF.md) | 运维交接 |
| [`tauapi-ops/docs/DEPLOYMENT.md`](tauapi-ops/docs/DEPLOYMENT.md) | 新服务器部署手册（面向 AI） |
| [`AGENTS.md`](AGENTS.md) | AI 维护约定与文档语言规则 |
| [`tauapi-fe/AGENTS.md`](tauapi-fe/AGENTS.md) | 前端规则（先读 `tauapi-fe/UPSTREAM_ROOT_AGENTS.md`） |
| [`tauapi-be/AGENTS.md`](tauapi-be/AGENTS.md) | 后端规则 |
