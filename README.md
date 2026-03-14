# Superpowers Skill Adapters

这个仓库做一件事：

把 [`obra/superpowers`](https://github.com/obra/superpowers) 的 upstream skill，接到 `Cline`、`Droid`、`OpenCode`、`CodeBuddy` 这四个宿主里，并补上中文触发和中文文档输出。

它不是把 upstream 全文翻译成中文。它做的是：

- 保留 upstream `SKILL.md` 主体基本为英文
- 给每个 skill 补中文触发词
- 让计划、评审、总结、方案等文档型输出默认用简体中文
- 新建文档但没指定文件名时，优先用中文文件名
- 在宿主差异大的地方加一层兼容规则，而不是手工重写整套 skill

## 先看最常用的命令

第一次安装，直接用：

```powershell
pwsh .\install-all.ps1 -Targets All -Scope User
```

安装到当前项目，不装到用户目录：

```powershell
pwsh .\install-all.ps1 -Targets All -Scope Project -ProjectRoot E:\path\to\project
```

这个仓库自己更新了，重新拉下来并重装：

```powershell
pwsh .\update-all.ps1 -Targets All -Scope User
```

上游 `obra/superpowers` 更新了，刷新 vendored upstream 再重装：

```powershell
pwsh .\refresh-upstream-and-reinstall.ps1 -Targets All -Scope User
```

如果你手上已经有一个新的 upstream 本地 checkout：

```powershell
pwsh .\refresh-upstream-and-reinstall.ps1 -SourcePath E:\path\to\superpowers -Targets All -Scope User
```

## 这几个脚本分别干什么

| 脚本 | 用途 |
| --- | --- |
| `install-all.ps1` | 用当前仓库里的内容安装到宿主 |
| `update-all.ps1` | 先更新这个适配仓库，再调用 `install-all.ps1` |
| `refresh-upstream-and-reinstall.ps1` | 先把 `vendor/superpowers` 刷到最新 upstream，再强制重装 |
| `scripts/Refresh-VendoredSuperpowers.ps1` | 只刷新 `vendor/superpowers`，不安装 |

如果你只是普通使用者，常用的是前两个。

如果你是维护这个适配仓库的人，最常用的是后两个。

## 支持哪些宿主

| 宿主 | 安装位置 | 适配方式 |
| --- | --- | --- |
| `Cline` | `.cline/skills` 或 `~/.cline/skills` | 生成 `prompt.md`，并写入中文规则 |
| `Droid` | `.factory/skills` 或 `~/.factory/skills` | 保留 skill 目录，附加 overlay 和 `AGENTS.md` |
| `OpenCode` | `.opencode/skill` 或 `~/.config/opencode/skill` | 按官方 `skill/*.md` 形式安装，并保留 companion 资源目录 |
| `CodeBuddy` | `.codebuddy/skills` | 项目根写入 `CODEBUDDY.md`，并写入中文语言设置 |

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
pwsh .\refresh-upstream-and-reinstall.ps1 -Targets All -Scope User
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
pwsh .\install-all.ps1 -Targets Cline -Scope User
pwsh .\install-all.ps1 -Targets Droid -Scope User
pwsh .\install-all.ps1 -Targets OpenCode -Scope User
pwsh .\install-all.ps1 -Targets CodeBuddy -Scope User
```

## 使用自己的 upstream 源

如果你不想用这个仓库里的 `vendor/superpowers`，也可以直接指定：

```powershell
pwsh .\install-all.ps1 -Targets All -Scope User -SourcePath E:\path\to\superpowers
```

或者指定一个单独的 vendor 目录：

```powershell
pwsh .\install-all.ps1 -Targets All -Scope User -VendorRoot $HOME\.superpowers\upstream
```

## 目录里这些文件有什么用

- `vendor/superpowers`
  - vendored upstream 本体
- `data/zh-cn-skill-triggers.json`
  - 中文触发词配置
- `templates/`
  - 各宿主的规则模板和 overlay
- `docs/`
  - 中文使用说明、兼容矩阵、发布说明

## 要注意的地方

- `User` scope 是“当前登录用户”，不是整台机器所有账号。
- `Cline` 通过 `prompt.md` 工作，所以它一定是复制安装。
- `OpenCode` 虽然是单文件 skill 入口，但 companion 目录也会一起复制，用来承接 `references/`、`scripts/` 等资源。
- `CodeBuddy` 的项目级结构是官方公开文档确认过的；用户级 `~/.codebuddy` 路径是兼容写法。

## 继续看文档

- [兼容性矩阵](docs/compatibility-matrix.md)
- [中文使用指南](docs/zh-cn-usage-guide.md)
- [贡献与维护说明](CONTRIBUTING.md)
- [发布到 GitHub](docs/publishing-to-github.md)

## 许可证

- 本仓库自己的适配层代码和文档使用 [MIT License](LICENSE)
- vendored upstream `obra/superpowers` 也使用 MIT，见 [NOTICE.md](NOTICE.md) 和 `vendor/superpowers/LICENSE`
