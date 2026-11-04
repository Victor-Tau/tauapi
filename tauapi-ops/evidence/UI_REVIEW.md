# Minimalist Flat — UI 评审摘要(fe-r3-0dab41b,2026-11-04)

设计来源:GOAL.md §9。实现规则:`docs/MINIMALIST_FLAT.md`。完整矩阵:`UI_INVENTORY.csv`(77 行:每个路由文件、11 个 section 注册表中的每个 `$section`、错误/认证/安装状态)。截图被 git 忽略,位于 `evidence/raw/` 下(仅限隔离的 QA 数据:QA 管理员、`qauser`、模拟渠道,无真实密钥或支付数据)。

## 变更内容(tauapi-fe 提交 3097ff7、0dab41b)

- **令牌**(`src/styles/theme.css`):page #FAFAFA/#111111,surface #FFFFFF/#1B1B1B,muted #F5F5F5/#262626,text #171717/#F5F5F5,secondary #525252/#A3A3A3,divider #E5E5E5/#333333,input border #737373,primary #1D4ED8/#93C5FD,primary-fg #FFFFFF/#111827,focus #2563EB/#93C5FD。基础圆角 6px;超过 8px 的圆角档位被封顶。
- **预设**保留其强调色;所有预设的表面保持中性;圆角偏好限制在 0–8px;字体、密度和布局偏好保留,localStorage 未改动。
- **基础组件**(`src/components/ui/*`):纯色遮罩(无背景模糊),无装饰性弹层阴影,细线 `border` 描边,实心 2px 焦点环,控件 36px / 粗指针设备 44px,表格行 48px,无按压缩放。
- **全局 CSS / 动效**:卡片无悬停抬升,行无入场错峰动画,玻璃效果工具类改为纯色,入场动画缩减为 ≤200 ms 的透明度渐变;遵循 `prefers-reduced-motion`。
- **功能**:涉及 170+ 个文件,覆盖首页、定价、排行、认证、安装、错误页、法务、仪表盘、使用日志、密钥、playground、钱包、个人资料、安全、渠道、模型、用户、订阅、任务插件、系统信息、系统设置、ai-elements、data-table。已移除装饰性渐变、光晕、玻璃效果、阴影、悬停缩放和过大的展示字体;装饰性的原始颜色已改用语义令牌。
- **有意保留**:测试所断言的状态色阶(成功率条、密钥配额)、图表配色、品牌和提供商 logo、加载/流式指示器、头像/圆点/开关的圆形形状、New API / QuantumNous 品牌、版权头和链接(已验证:0 个头部丢失)。
- **新增**:移动端导航触发器的可访问名称;一个非强制的新版本提示。

## 验证

| 检查项 | 结果 |
| --- | --- |
| 类型检查 / 单元测试 | 通过 / 202 个文件,2465 个测试通过(与上游基线数量相同) |
| Lint | 变更文件:错误集合与这些文件的上游版本相同(上游基线有 152 个 lint 错误,列表一致) |
| 页面矩阵(QA) | 231 个页面 × 视口/主题截图中有 230 个到达目标页面且标记可见;无页面级横向溢出。例外:`oauth-cb` 移动端在截图前重定向到 `/sign-in`(无效 code 时属预期;桌面端截图显示等待状态),以及 model-pricing 移动端渲染时标题滚动到了标签栏之下 |
| 浮层 / 菜单 / 抽屉(QA) | 对话框、命令面板、个人资料菜单、主题抽屉、渠道抽屉、选择弹层、图表(canvas)、移动端侧边栏面板、移动端公共菜单 — 浅色与深色:17/17 已渲染 |
| 安装向导 | 针对真实的未初始化一次性后端,第 1–4 步:桌面浅色/深色及移动浅色;完成后落在 `/` |
| 对比度 | `evidence/ui/CONTRAST.md`:16/16 个必需配对通过(文本 ≥ 4.5:1,控件/焦点 ≥ 3:1) |
| 键盘 | 登录页 Tab 顺序 用户名 → 密码 → 显示密码 → 忘记密码 → 提交,每项都有可见焦点环和 `<label>`;Enter 提交并显示字段错误;对话框可通过键盘打开,焦点移入其中,Escape 关闭且焦点返回触发器;Ctrl+K 打开命令面板;修复后顶栏/侧边栏中无未命名的图标按钮 |
| zh @ 200% 缩放 | 7 个代表性页面,720×450 CSS px,devicePixelRatio 2:无横向溢出 |
| 权限 | 普通用户:/channels、/users、/system-settings/*、/task-plugins → /403;管理员菜单隐藏;`/api/channel/` → 401 |
| Playground | 来自模拟模型的流式回复,Stop 在 20 个分块中的第 2 个后终止,错误模型显示错误 |

## 实际打开并检查过的截图

home(浅色/深色桌面)、pricing(浅色桌面)、sign-in(深色移动)、keys(浅色移动)、playground(深色移动,已停止的流)、dashboard overview(浅色桌面)、dashboard models charts(浅色)、channels(深色桌面)、create-channel drawer(浅色,fe-r2 与 fe-r3)、users(浅色移动)、usage logs(深色桌面)、security(浅色桌面)、system settings › operations › behavior(深色桌面)、billing › model pricing(浅色移动)、error 500(浅色)、API key dialog(深色)、theme drawer(浅色)、command palette(深色)、mobile sidebar sheet(深色)、setup wizard steps 2–3(浅色/深色)、zh 200% channels。

评审中发现并已修复的问题:渠道选择器的搜索框仍使用旧的半透明输入填充(已在 fe-r3 修复,command/combobox/tabs/input-group/json editor 均改用 input 令牌填充);主题抽屉的圆角标签显示旧的 rem 值(已修复);移动端导航触发器没有可访问名称(已修复)。

## 非第一方 / 未重新设计样式

OAuth 提供商站点、支付提供商页面、第三方 iframe 以及用户提供的 HTML/Markdown 内容。它们的入口、容器、加载和错误状态属于第一方,已在上文覆盖。SMTP/OAuth/支付流程在生产环境中未配置(见 HANDOFF.md)。
