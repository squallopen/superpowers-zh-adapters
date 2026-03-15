# 贡献与维护说明

这个仓库不是在“重写一套中文 superpowers”。

下文把 `Cline`、`Droid`、`OpenCode`、`CodeBuddy` 统称为“工具”。

维护时请始终按下面这条边界来做：

- 原版仓库 `obra/superpowers` 继续作为事实来源
- 本仓库主要维护工具适配层、中文触发提示、中文文档输出约束
- 不要为了中文化去大规模改写原版 skill 主体
- 能用工具自带机制时，优先用工具自带机制

## 仓库结构

| 路径 | 作用 |
| --- | --- |
| `vendor/superpowers` | vendored 原版 skill 全量内容 |
| `templates` | 各工具的 overlay、规则块、说明块 |
| `data/zh-cn-skill-triggers.json` | skill 名称到中文触发提示的映射 |
| `scripts/powershell/Install-Superpowers.Common.psm1` | 公共安装函数 |
| `scripts/powershell/install-*.ps1` | 各工具安装脚本 |
| `scripts/powershell/install-all.ps1` | 批量安装入口 |
| `scripts/powershell/update-all.ps1` | 更新当前仓库并重装 |
| `scripts/powershell/refresh-upstream-and-reinstall.ps1` | 刷新 vendored 原版 skill 后强制重装 |
| `README.md` | 首页落地页，先讲价值、安全和安装入口 |
| `docs/ai-agent-install.md` | 给 AI agent 和普通用户直接复制的安装说明 |
| `docs/customize-triggers.md` | 自定义中文触发词的最短说明 |
| `docs/*-zh-prompts.md` | 四个工具各自的使用方式、示例 prompt 和触发方式 |

## 脚本目录规范

- 当前官方只维护 `scripts/powershell/`
- 当前脚本链路只面向 `Windows + PowerShell 7 + Git for Windows`
- 仓库根目录不再放安装脚本
- 如果以后有人要补其他系统，请在 `scripts/<runtime>/` 下新增，不要把逻辑继续堆进 `scripts/powershell/`
- 新运行时尽量沿用同名入口：`install-all`、`update-all`、`refresh-upstream-and-reinstall`、`install-<host>`

## 文档写法约束

- `README.md` 保持“落地页”风格：先讲它能做什么、为什么安全、怎么安装，再把细节导到 `docs/`
- 不要把工具细节、完整 prompt 集合、维护细节全部堆回首页
- 工具差异放到各自文档，例如 `docs/cline-zh-prompts.md`
- 触发词自定义说明尽量集中在 `docs/customize-triggers.md`
- 适合画流程、决策树、工作流的内容，优先用 Mermaid，不要只写成长段文字

## 用户配置保护策略

- 不要整文件覆盖用户现有的 `AGENTS.md`、`CODEBUDDY.md`
- `AGENTS.md` / `CODEBUDDY.md` 只允许改本适配仓库写入的专用说明段
- 如果我们那一段的开始/结束标记不完整、重复、顺序异常，脚本要直接停止，不能猜着写
- `CodeBuddy` 的 `.codebuddy/settings.json` 不要强改用户已经存在的 `language`
- `Cline` 不要占用通用规则文件名，避免撞用户已有的 `00-*`、`10-*` 规则
- 改动前先自动备份
- 备份要按“单次执行一个批次目录”来组织：`User` scope 放在 `~/.superpowers-backups/<时间戳>/`，`Project` scope 放在 `<项目根>/.superpowers-backups/<时间戳>/`
- 同一次执行产生的备份，要在这个批次目录下再按工具分目录，例如 `cline/`、`droid/`、`opencode/`、`codebuddy/`
- 工具目录下再按 `skills`、`files`、`legacy-skill-backups` 归类，不能把整包 skill 备份留在 `skills` / `skill` 目录里
- 如果发现旧版把备份目录留在工具的 `skills` / `skill` 目录里，脚本要先迁走；迁不动就停止并提示用户手工处理
- 如果遇到旧版遗留文件、格式冲突、或看不准是不是用户自己写的内容，先告诉用户怎么合并，再等用户确认
- 如果某个工具里已经装过我们的 superpowers skill，默认按工具只问一次：覆盖、只补缺少的、或取消；不要刷一长串吓人的 warning
- `update-all.ps1` 和 `refresh-upstream-and-reinstall.ps1` 这种“更新型”入口，要先明确提醒“接下来会覆盖已有 superpowers 安装”，确认后再继续；只有 `-AssumeYes` 才能跳过这一步
- 安装前先展示“当前已装 superpowers 原仓库版本”和“本次准备安装的 superpowers 原仓库版本”；优先显示版本 tag，并尽量带上日期；拿不到时再明确显示未知
- 如果覆盖旧 skill 时自动删除失败，不要继续硬装；要提示用户手工删除，再等用户确认

推荐备份这些文件：

- `AGENTS.md`
- `CODEBUDDY.md`
- `.codebuddy/settings.json`
- `.clinerules/90-superpowers-bootstrap.md`
- `.clinerules/91-superpowers-skill-triggers-zh-cn.md`
- `.clinerules/92-superpowers-output-docs-zh-cn.md`
- 以及旧版 `Cline` 规则文件 `00/05/10`

## 日常维护流程

### 1. 只更新适配层

如果只是改模板、触发词、文档或安装逻辑，直接在当前仓库改：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets All -Scope Project -ProjectRoot E:\path\to\sandbox -Force
```

推荐先装到一个临时项目里验证，再决定是否推用户级目录。

说明：

- 不加 `-Force` 时，如果工具里已经有 superpowers skill，脚本会提示你选覆盖、只补缺少的、或取消
- 加 `-Force` 代表你就是要直接覆盖，不再二次确认
- 加 `-AssumeYes` 代表需要自动确认，适合脚本化场景
- 如果 `-Force` / `-AssumeYes` 过程中删除旧 skill 失败，脚本应该停下来报清楚，不要偷偷跳过

### 2. 同步原版仓库

如果 `obra/superpowers` 更新了，优先用完整刷新流程：

```powershell
pwsh .\scripts\powershell\refresh-upstream-and-reinstall.ps1 -Targets All -Scope Project -ProjectRoot E:\path\to\sandbox
```

默认会优先取原版仓库最新版本 tag，不直接追 `main`；只有你显式传 `-Ref main` 时才会用 `main`。

如果你已经有一个原版 skill 的本地目录：

```powershell
pwsh .\scripts\powershell\refresh-upstream-and-reinstall.ps1 -SourcePath E:\path\to\superpowers -Targets All -Scope Project -ProjectRoot E:\path\to\sandbox
```

这个脚本会额外检查两件事：

- 有没有新的原版 skill 还没写中文触发词
- `data/zh-cn-skill-triggers.json` 里有没有已经失效的旧条目

如果只想刷新 `vendor/superpowers`，不安装：

```powershell
pwsh .\scripts\powershell\Refresh-VendoredSuperpowers.ps1
```

## 修改 skill 触发或输出行为

### 中文触发

统一改 [data/zh-cn-skill-triggers.json](data/zh-cn-skill-triggers.json)。

原则：

- 保持触发短语贴近中文真实说法，不要堆同义词
- 优先覆盖“计划、评审、调试、并行代理、TDD、头脑风暴”这类高频表达
- 新增原版 skill 时，必须补对应中文触发条目

### 中文文档输出

统一通过工具模板层约束，不直接改原版 skill 主体。

当前实现方式：

- `Cline` 通过规则文件约束文档输出为简体中文
- `Droid`、`OpenCode`、`CodeBuddy` 通过 overlay / `AGENTS.md` / `CODEBUDDY.md` 注入约束
- 未指定文档名时，优先使用中文文件名
- 未指定路径时，文档型文件默认优先放 `docs/`
- 文档型输出除了必要技术术语外，尽量写得通俗易懂
- `Cline` 使用专用规则文件名 `90-superpowers-*.md`，不再占用早期那组通用文件名
- `AGENTS.md` / `CODEBUDDY.md` 只有在能明确识别出本适配仓库写入的专用说明段时才会更新；识别不准就停下来

如果要改这类行为，先看：

- [templates/cline/rules/10-output-docs-zh-cn.md](templates/cline/rules/10-output-docs-zh-cn.md)
- [templates/droid/AGENTS.block.md](templates/droid/AGENTS.block.md)
- [templates/opencode/AGENTS.block.md](templates/opencode/AGENTS.block.md)
- [templates/codebuddy/CODEBUDDY.block.md](templates/codebuddy/CODEBUDDY.block.md)

## 新增一个工具适配时怎么做

请尽量遵守下面这几个约束：

1. 先确认这个工具官方支持的 skill / instruction 入口形式。
2. 优先复用原版 skill 文件和资源目录，不要手工复制改写每个 skill。
3. 中文化只放在适配层，不放在 vendored 原版 skill。
4. 安装脚本要支持 `User` 和 `Project` 两种作用域，除非这个工具本身不支持。
5. 如果这个工具支持链接安装和复制安装，优先把复制模式做稳，再考虑 `Junction`。

最小落地清单：

1. 新增 `scripts/powershell/install-<host>.ps1`
2. 在 [scripts/powershell/install-all.ps1](scripts/powershell/install-all.ps1) 和 [scripts/powershell/refresh-upstream-and-reinstall.ps1](scripts/powershell/refresh-upstream-and-reinstall.ps1) 接入
3. 在 `templates/<host>/` 放工具专属 overlay 或说明块
4. 在 [docs/compatibility-matrix.md](docs/compatibility-matrix.md) 补兼容说明
5. 在 [README.md](README.md)、[docs/zh-cn-usage-guide.md](docs/zh-cn-usage-guide.md) 和必要时对应工具文档里补用法

## 验证建议

当前仓库没有把每个工具的 GUI 全自动化，所以维护时至少做这些检查：

### 安装检查

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets All -Scope Project -ProjectRoot E:\path\to\sandbox -Force
```

确认输出里的 `Installed` 数量和原版 skill 数量一致。

### 刷新检查

```powershell
pwsh .\scripts\powershell\refresh-upstream-and-reinstall.ps1 -SourcePath E:\path\to\superpowers -Targets All -Scope Project -ProjectRoot E:\path\to\sandbox
```

确认没有缺失 trigger 的 warning；如果有，就先补 `data/zh-cn-skill-triggers.json`。

### 工具抽样检查

至少抽样看下面这些文件是否生成正确：

- `.cline/skills/<skill>/prompt.md`
- `.clinerules/90-superpowers-bootstrap.md`
- `.clinerules/91-superpowers-skill-triggers-zh-cn.md`
- `.clinerules/92-superpowers-output-docs-zh-cn.md`
- `.factory/skills/<skill>/SKILL.md`
- `.opencode/skill/<skill>.md`
- `.opencode/skill/<skill>/`
- `.codebuddy/skills/<skill>/SKILL.md`
- `AGENTS.md` 或 `CODEBUDDY.md`

另外要检查：

- `AGENTS.md` / `CODEBUDDY.md` 是否只改了本适配仓库写入的专用说明段
- 如果手工制造半截标记或重复标记，脚本是否会停止，而不是继续往里写
- `.codebuddy/settings.json` 如果原来已有 `language`，脚本是否只告警而没有强改
- 安装前是否能正确展示“当前已装版本”和“准备安装版本”
- 如果旧 skill 删除失败，脚本是否会提示手工删除并等待确认

## 发布流程

### 代码推送

```powershell
git add .
git commit -m "<message>"
git push origin main
```

### 打版本

```powershell
git tag -a v0.x.y -m "v0.x.y"
git push origin v0.x.y
```

### 发 GitHub Release

推荐直接用 `gh`：

```powershell
gh release create v0.x.y --title "v0.x.y <标题>" --notes "<发布说明>"
```

发布说明建议写清楚：

- 支持了哪些工具
- 这次同步到了哪个 upstream 状态
- 是否新增或调整了中文触发规则
- 是否有“安装层已验证，但 GUI 尚未全量人工回归”的边界

## 提交风格建议

- 涉及 upstream 同步时，提交信息里明确写 `Refresh vendored superpowers`
- 只改适配层时，提交信息里写清楚工具或行为，例如 `Improve CodeBuddy installation docs`
- 不要把 vendored upstream 改动和大段文档重写、工具逻辑改动混在一个提交里
