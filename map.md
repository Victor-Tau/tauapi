# TauAPI 系统地图

当前维护入口为[文档首页](docs/zh-CN/README.md)，AI 从[英文索引](docs/ai/INDEX.md)按任务选择文档。

| 目录 | 职责 |
| --- | --- |
| tauapi-fe | 独立构建发布的 React 静态前端 |
| tauapi-be | 纯 API 后端，含 RelayKit、TokenKit 独立模块 |
| tauapi-ops | Nginx 路由契约、发布、备份、隔离 QA |
| docs/ai | 技术契约、任务路由、变更记录与校验规则 |
| docs/zh-CN | 面向使用者的说明与运维入口 |

请求经 Nginx 分流：已登记的页面与静态资源走前端，其他路径进入后端，再由 API 或插件处理。
前后端同源，通过相对 URL 调用。构建各自导出一个子目录，不依赖另一端的源码。

生产约定目录为 /srv/tauapi，秘密为 /etc/tauapi；QA 使用独立命名与回环端口。
这些是配置约定，不代表本次已检查运行状态。
历史交付见[tauapi-ops/HANDOFF.md](tauapi-ops/HANDOFF.md)；部署 JSON 仅代表其采集时间。
详细架构和源码入口见[英文系统地图](docs/ai/REPOSITORY_MAP.md)。
