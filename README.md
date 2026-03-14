# Superpowers Skill Adapters

这个仓库做一件事：

把 [`obra/superpowers`](https://github.com/obra/superpowers) 的 upstream skill，接到 `Cline`、`Droid`、`OpenCode`、`CodeBuddy` 这四个宿主里，并补上中文触发和中文文档输出。

它不是把 upstream 全文翻译成中文。它做的是：

- 保留 upstream `SKILL.md` 主体基本为英文
- 给每个 skill 补中文触发词
- 让计划、评审、总结、方案等文档型输出默认用简体中文
- 新建文档但没指定文件名时，优先用中文文件名
- 在宿主差异大的地方加一层兼容规则，而不是手工重写整套 skill

## 当前官方支持环境

- `Windows`
- `PowerShell 7`（命令是 `pwsh`）
- `Git for Windows`

当前仓库的正式脚本入口都在 [scripts/powershell/](scripts/powershell)，其他操作系统暂时不官方维护；如果以后有人要补，可以按 [scripts/README.md](scripts/README.md) 的目录规范新增运行时。

## 先看最常用的命令

第一次安装，直接用：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets All -Scope User
```

执行前，脚本会先展示两行版本信息：

- 当前已装的 upstream 版本
- 这次准备安装的 upstream 版本

版本展示会优先用 upstream 的版本 tag；如果有日期，也会一起带上。
拿不到 tag 时才退回 commit；再拿不到才显示“未知”。

安装到当前项目，不装到用户目录：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets All -Scope Project -ProjectRoot E:\path\to\project
```

这个仓库自己更新了，重新拉下来并重装：

```powershell
pwsh .\scripts\powershell\update-all.ps1 -Targets All -Scope User
```

这个命令会先提醒你“这是更新，会覆盖已有 superpowers 安装”；确认后才继续。想在无人值守场景里自动继续，可以额外加 `-AssumeYes`。

上游 `obra/superpowers` 更新了，刷新 vendored upstream 再重装：

```powershell
pwsh .\scripts\powershell\refresh-upstream-and-reinstall.ps1 -Targets All -Scope User
```

这个命令同样会先确认，再执行覆盖式重装；只有加了 `-AssumeYes` 才会跳过确认。
默认会优先刷新到 upstream 最新版本 tag，不是直接追 `main`。

如果你手上已经有一个新的 upstream 本地 checkout：

```powershell
pwsh .\scripts\powershell\refresh-upstream-and-reinstall.ps1 -SourcePath E:\path\to\superpowers -Targets All -Scope User
```

## 这几个脚本分别干什么

| 脚本 | 用途 |
| --- | --- |
| `scripts/powershell/install-all.ps1` | 用当前仓库里的内容安装到宿主 |
| `scripts/powershell/update-all.ps1` | 先更新这个适配仓库，确认后再按“覆盖更新”方式重装 |
| `scripts/powershell/refresh-upstream-and-reinstall.ps1` | 先把 `vendor/superpowers` 刷到最新 upstream，确认后再按“覆盖更新”方式重装 |
| `scripts/powershell/Refresh-VendoredSuperpowers.ps1` | 只刷新 `vendor/superpowers`，不安装 |

如果你只是普通使用者，常用的是前两个。

如果你是维护这个适配仓库的人，最常用的是后两个。

## 支持哪些宿主

| 宿主 | 安装位置 | 适配方式 |
| --- | --- | --- |
| `Cline` | `.cline/skills` 或 `~/.cline/skills` | 生成 `prompt.md`，并写入中文规则 |
| `Droid` | `.factory/skills` 或 `~/.factory/skills` | 保留 skill 目录，附加 overlay 和 `AGENTS.md` |
| `OpenCode` | `.opencode/skill` 或 `~/.config/opencode/skill` | 按官方 `skill/*.md` 形式安装，并保留 companion 资源目录 |
| `CodeBuddy` | `.codebuddy/skills` | 项目根写入 `CODEBUDDY.md`，并写入中文语言设置 |

## 配置覆盖策略

- `Cline`：只写我们自己的 3 个专用规则文件，不会去改你别的规则文件
- `Droid` / `OpenCode`：只改 `AGENTS.md` 里我们自己加进去的那一段，别的内容不动
- `CodeBuddy`：只改 `CODEBUDDY.md` 里我们自己加进去的那一段
- `CodeBuddy` 的 `.codebuddy/settings.json`：如果你已经写了 `language`，脚本会保留原值，不会硬改
- 如果 `AGENTS.md` / `CODEBUDDY.md` 里我们那一段的开始和结束标记不完整、重复、顺序不对，脚本会直接停下来，不会硬写，避免把你的文件弄乱

当前 `Cline` 专用 rule 文件名是：

- `90-superpowers-bootstrap.md`
- `91-superpowers-skill-triggers-zh-cn.md`
- `92-superpowers-output-docs-zh-cn.md`

如果你是从这个仓库的早期版本升级上来，目录里可能还留着旧文件：

- `00-superpowers-bootstrap.md`
- `05-skill-triggers-zh-cn.md`
- `10-output-docs-zh-cn.md`

这 3 个旧文件现在不会被脚本自动删除，避免误删你的自定义内容。你需要自己检查后再决定是否删除。

## 备份和人工确认

脚本在改下面这些文件前，会先在原目录旁边留一份备份，文件名类似：

- `原文件名.superpowers.bak-时间戳`

会自动备份的重点文件：

- `Cline` 的专用规则文件
- `Droid` / `OpenCode` 的 `AGENTS.md`
- `CodeBuddy` 的 `CODEBUDDY.md`
- `CodeBuddy` 的 `.codebuddy/settings.json`（仅在脚本准备补 `language` 时）

如果脚本发现某个宿主里已经装过我们的 superpowers skill，它不会再一条条刷很多 `WARNING`，而是会按宿主只问你一次：

- 输入 `YES`：覆盖旧的 superpowers skill，脚本会先自动备份
- 输入 `SKIP`：保留旧的，只补缺少的
- 输入别的内容：直接取消

只有两种情况会跳过这一步确认：

- 你明确传了 `-Force`
- 你明确传了 `-AssumeYes`

如果脚本在覆盖旧 skill 时自动删除失败，也不会继续硬装，而是会：

1. 直接告诉你删哪个目录
2. 等你手工删完后输入 `YES`
3. 确认目录真的没了，再继续

如果你用了 `-AssumeYes`，脚本没法等你现场确认，这种情况下会直接退出，并提示你先手工删除再重跑。

如果脚本发现你机器上还有旧版 `Cline` 规则文件，它不会替你乱删，而是会：

1. 先帮你备份旧文件
2. 告诉你怎么自己看、自己合并
3. 等你确认后再继续

`update-all.ps1` 和 `refresh-upstream-and-reinstall.ps1` 这两个“更新型”命令，也会先单独提醒一次“接下来会覆盖已有 superpowers 安装”；确认后才继续。

## 这个仓库现在做到什么程度

- 已 vendored 完整 upstream，不是只挑几个 skill
- 当前 upstream 共 14 个真实 skill
- 四个宿主都已经做了安装脚本
- 中文对话可以更稳定地触发 skill
- 文档型输出默认是中文
- `OpenCode` 已按官方 `skill/*.md` 结构适配
- `CodeBuddy` 项目级结构按官方公开文档适配

更准确地说，这个仓库已经完成了“整套 skill 的中文可用性适配”，但不是“整套 skill 的中文全文翻译”。

## 如果上游更新了，维护麻烦吗

不麻烦，正常情况就是两步：

1. 刷新 upstream
2. 重新安装

现在已经有一条命令把这两步串起来：

```powershell
pwsh .\scripts\powershell\refresh-upstream-and-reinstall.ps1 -Targets All -Scope User
```

脚本会顺带帮你检查两件事：

- upstream 里有没有新增 skill，但 `data/zh-cn-skill-triggers.json` 里还没加中文触发词
- `data/zh-cn-skill-triggers.json` 里有没有已经失效的旧条目

通常情况下：

- 如果 upstream 只是改已有 skill 内容，基本可以直接刷新
- 如果 upstream 新增 skill、删 skill、改 skill 名，通常只需要顺手更新 `data/zh-cn-skill-triggers.json`
- 如果 upstream 大改了某几个 skill 的结构，才需要回头看 overlay 是否也要跟着调

## 只装某一个宿主

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets Cline -Scope User
pwsh .\scripts\powershell\install-all.ps1 -Targets Droid -Scope User
pwsh .\scripts\powershell\install-all.ps1 -Targets OpenCode -Scope User
pwsh .\scripts\powershell\install-all.ps1 -Targets CodeBuddy -Scope User
```

## 使用自己的 upstream 源

如果你不想用这个仓库里的 `vendor/superpowers`，也可以直接指定：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets All -Scope User -SourcePath E:\path\to\superpowers
```

或者指定一个单独的 vendor 目录：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets All -Scope User -VendorRoot $HOME\.superpowers\upstream
```

## 目录里这些文件有什么用

- `vendor/superpowers`
  - vendored upstream 本体
- `data/zh-cn-skill-triggers.json`
  - 中文触发词配置
- `templates/`
  - 各宿主的规则模板和 overlay
- `scripts/powershell/`
  - 当前官方维护的 Windows PowerShell 安装脚本
- `scripts/README.md`
  - 脚本目录规范，给未来其他运行时预留结构
- `docs/`
  - 中文使用说明、兼容矩阵、发布说明

## 要注意的地方

- `User` scope 是“当前登录用户”，不是整台机器所有账号。
- 当前官方只维护 `Windows + PowerShell 7 + Git for Windows` 这条脚本链路。
- `Cline` 现在使用专用 rule 文件名，避免撞上你原来常见的 `00-*` / `10-*` 规则文件。
- `Droid` / `OpenCode` / `CodeBuddy` 的说明文件不会整文件盖掉；正常重装时只会更新我们自己那一段。
- 如果 `AGENTS.md` / `CODEBUDDY.md` 里我们那一段标记异常，脚本会直接停下来，避免误追加第二份或误覆盖你的内容。
- 安装前会先显示“当前已装版本”和“准备安装版本”；优先显示版本 tag，并尽量把日期也带上。
- 如果你已经在 `.codebuddy/settings.json` 里设置了 `language`，脚本会保留你的值；想切成中文请自己改成 `简体中文`。
- `Cline` 通过 `prompt.md` 工作，所以它一定是复制安装。
- `OpenCode` 虽然是单文件 skill 入口，但 companion 目录也会一起复制，用来承接 `references/`、`scripts/` 等资源。
- `CodeBuddy` 的项目级结构是官方公开文档确认过的；用户级 `~/.codebuddy` 路径是兼容写法。

想让仓库里的 `vendor/superpowers` 也带上可识别的上游版本记录，最稳妥的方式是执行一次：

```powershell
pwsh .\scripts\powershell\refresh-upstream-and-reinstall.ps1 -Targets All -Scope User
```

## 继续看文档

- [兼容性矩阵](docs/compatibility-matrix.md)
- [中文使用指南](docs/zh-cn-usage-guide.md)
- [贡献与维护说明](CONTRIBUTING.md)
- [发布到 GitHub](docs/publishing-to-github.md)

## 许可证

- 本仓库自己的适配层代码和文档使用 [MIT License](LICENSE)
- vendored upstream `obra/superpowers` 也使用 MIT，见 [NOTICE.md](NOTICE.md) 和 `vendor/superpowers/LICENSE`
