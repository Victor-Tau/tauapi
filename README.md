# TauAPI

由 [new-api](https://github.com/QuantumNous/new-api) 二次开发。

前端、纯 API 后端独立构建发布。

- [文档首页](docs/zh-CN/README.md)：使用、运维和维护方式。
- [系统地图](map.md)：目录与运行边界。
- [AI 维护入口](docs/ai/INDEX.md)：任务路由、契约与校验。
- [文档体系交付说明](docs/zh-CN/documentation-system-handoff.md)：本次结果和限制。

在仓库根目录运行 `make docs-setup`，再运行 `make docs-check docs-test`。
本项目不使用 GitHub Actions；文档、测试与发布校验按需在本地执行。
历史验收记录只适用于当时的环境与版本，不代表当前部署状态。
