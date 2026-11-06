# 文档首页

[系统地图](../../map.md)介绍仓库分工；[登录说明](authentication.md)介绍会话与令牌。
[文档体系交付说明](documentation-system-handoff.md)记录验证范围与尚未启用的远程能力。

提出需求时，请说明希望发生的行为、当前问题和验收条件。维护代理会按任务与文件影响
选择技术契约，修改实现时同步维护文档，并报告实际检查结果。

文档管理使用 `make docs-check`；任务影响使用 `make docs-impact-worktree DOCS_BASE=<版本>`。
新增文档需要登记，任务导航由工具生成。人读说明写简体中文，AI 技术规范写英文。
初始化材料保留在 docs/_bootstrap，仅供溯源。

运维人员从[运维索引](../../tauapi-ops/docs/ai/INDEX.md)进入新主机和备份恢复流程。
发布兼容性、schema 回滚保护和动态路由覆盖仍有已知缺口，详见[技术问题清单](../ai/KNOWN_GAPS.md)。
生产部署、恢复与远程发布需有相应授权，本次文档重构未执行这些操作。
