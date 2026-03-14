# 贡献与维护说明

这个仓库不是在“重写一套中文 superpowers”。

维护时请始终按下面这条边界来做：

- upstream `obra/superpowers` 继续作为事实来源
- 本仓库主要维护宿主适配层、中文触发提示、中文文档输出约束
- 不要为了中文化去大规模改写 upstream skill 主体
- 能用宿主原生机制时，优先用宿主原生机制

## 仓库结构

| 路径 | 作用 |
| --- | --- |
| `vendor/superpowers` | vendored upstream 全量内容 |
| `templates` | 各宿主的 overlay、规则块、说明块 |
| `data/zh-cn-skill-triggers.json` | skill 名称到中文触发提示的映射 |
| `scripts/powershell/Install-Superpowers.Common.psm1` | 公共安装函数 |
| `scripts/powershell/install-*.ps1` | 各宿主安装脚本 |
| `scripts/powershell/install-all.ps1` | 批量安装入口 |
| `scripts/powershell/update-all.ps1` | 更新当前仓库并重装 |
| `scripts/powershell/refresh-upstream-and-reinstall.ps1` | 刷新 vendored upstream 后强制重装 |

## 脚本目录规范

- 当前官方只维护 `scripts/powershell/`
- 当前脚本链路只面向 `Windows + PowerShell 7 + Git for Windows`
- 仓库根目录不再放安装脚本
- 如果以后有人要补其他系统，请在 `scripts/<runtime>/` 下新增，不要把逻辑继续堆进 `scripts/powershell/`
- 新运行时尽量沿用同名入口：`install-all`、`update-all`、`refresh-upstream-and-reinstall`、`install-<host>`

## 日常维护流程

### 1. 只更新适配层

如果只是改模板、触发词、文档或安装逻辑，直接在当前仓库改：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets All -Scope Project -ProjectRoot E:\path\to\sandbox -Force
```

推荐先装到一个临时项目里验证，再决定是否推用户级目录。

### 2. 同步 upstream

如果 `obra/superpowers` 更新了，优先用完整刷新流程：

```powershell
pwsh .\scripts\powershell\refresh-upstream-and-reinstall.ps1 -Targets All -Scope Project -ProjectRoot E:\path\to\sandbox
```

如果你已经有一个本地 upstream checkout：

```powershell
pwsh .\scripts\powershell\refresh-upstream-and-reinstall.ps1 -SourcePath E:\path\to\superpowers -Targets All -Scope Project -ProjectRoot E:\path\to\sandbox
```

这个脚本会额外检查两件事：

- 有没有新的 upstream skill 还没写中文触发词
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
- 新增 upstream skill 时，必须补对应中文触发条目

### 中文文档输出

统一通过宿主模板层约束，不直接改 upstream skill 主体。

当前实现方式：

- `Cline` 通过规则文件约束文档输出为简体中文
- `Droid`、`OpenCode`、`CodeBuddy` 通过 overlay / `AGENTS.md` / `CODEBUDDY.md` 注入约束
- 未指定文档名时，优先使用中文文件名

如果要改这类行为，先看：

- [templates/cline/rules/10-output-docs-zh-cn.md](templates/cline/rules/10-output-docs-zh-cn.md)
- [templates/droid/AGENTS.block.md](templates/droid/AGENTS.block.md)
- [templates/opencode/AGENTS.block.md](templates/opencode/AGENTS.block.md)
- [templates/codebuddy/CODEBUDDY.block.md](templates/codebuddy/CODEBUDDY.block.md)

## 新增一个宿主适配时怎么做

请尽量遵守下面这几个约束：

1. 先确认宿主官方支持的 skill / instruction 入口形式。
2. 优先复用 upstream skill 文件和资源目录，不要手工复制改写每个 skill。
3. 中文化只放在适配层，不放在 vendored upstream。
4. 安装脚本要支持 `User` 和 `Project` 两种作用域，除非宿主本身不支持。
5. 如果宿主支持链接安装和复制安装，优先把复制模式做稳，再考虑 `Junction`。

最小落地清单：

1. 新增 `scripts/powershell/install-<host>.ps1`
2. 在 [scripts/powershell/install-all.ps1](scripts/powershell/install-all.ps1) 和 [scripts/powershell/refresh-upstream-and-reinstall.ps1](scripts/powershell/refresh-upstream-and-reinstall.ps1) 接入
3. 在 `templates/<host>/` 放宿主专属 overlay 或说明块
4. 在 [docs/compatibility-matrix.md](docs/compatibility-matrix.md) 补兼容说明
5. 在 [README.md](README.md) 和 [docs/zh-cn-usage-guide.md](docs/zh-cn-usage-guide.md) 补用法

## 验证建议

当前仓库没有把每个宿主 GUI 全自动化，所以维护时至少做这些检查：

### 安装检查

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets All -Scope Project -ProjectRoot E:\path\to\sandbox -Force
```

确认输出里的 `Installed` 数量和 upstream skill 数量一致。

### 刷新检查

```powershell
pwsh .\scripts\powershell\refresh-upstream-and-reinstall.ps1 -SourcePath E:\path\to\superpowers -Targets All -Scope Project -ProjectRoot E:\path\to\sandbox
```

确认没有缺失 trigger 的 warning；如果有，就先补 `data/zh-cn-skill-triggers.json`。

### 宿主抽样检查

至少抽样看下面这些文件是否生成正确：

- `.cline/skills/<skill>/prompt.md`
- `.clinerules/05-skill-triggers-zh-cn.md`
- `.factory/skills/<skill>/SKILL.md`
- `.opencode/skill/<skill>.md`
- `.opencode/skill/<skill>/`
- `.codebuddy/skills/<skill>/SKILL.md`
- `AGENTS.md` 或 `CODEBUDDY.md`

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

- 支持了哪些宿主
- 这次同步到了哪个 upstream 状态
- 是否新增或调整了中文触发规则
- 是否有“安装层已验证，但 GUI 尚未全量人工回归”的边界

## 提交风格建议

- 涉及 upstream 同步时，提交信息里明确写 `Refresh vendored superpowers`
- 只改适配层时，提交信息里写清楚宿主或行为，例如 `Improve CodeBuddy installation docs`
- 不要把 vendored upstream 改动和大段文档重写、宿主逻辑改动混在一个提交里
