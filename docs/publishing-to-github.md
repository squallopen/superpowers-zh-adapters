# 发布到 GitHub

这份仓库现在已经基本是“可发布”状态，但真正发到 GitHub 还需要你做两件事：

1. 确定仓库名、可见性和顶层许可证
2. 绑定你自己的 GitHub remote 并 push

## 发布前检查

- 确认 `vendor/superpowers` 只是普通文件目录，不再带自己的 `.git`
- 确认 [README.md](../README.md) 仍然是一眼能看懂的首页，而不是把全部细节重新堆回去
- 确认 [docs/compatibility-matrix.md](compatibility-matrix.md)、[docs/zh-cn-usage-guide.md](zh-cn-usage-guide.md)、[docs/ai-agent-install.md](ai-agent-install.md)、[docs/customize-triggers.md](customize-triggers.md) 内容符合你想公开的描述
- 如果发布说明会提到 `Codex`，要同时写清楚“可安全使用”的前提是适配层已经把 worktree / branch finishing 的危险场景硬约束住，不是说它和上游完全一样
- 如果你要公开发布，补一个顶层 `LICENSE`

## 本地初始化

如果当前目录还不是 git 仓库：

```powershell
git init -b main
git add .
git commit -m "Initial import of superpowers adapters"
```

## 创建 GitHub 仓库并推送

如果你装了 GitHub CLI：

```powershell
gh repo create <owner>/<repo> --source . --public --push
```

如果你要手动创建远程仓库：

```powershell
git remote add origin https://github.com/<owner>/<repo>.git
git push -u origin main
```

## 对外安装说明

发布后，推荐的安装方式是：

```powershell
git clone https://github.com/<owner>/<repo>.git
cd <repo>
pwsh .\scripts\powershell\install-all.ps1 -Targets All -Scope User
```

只装 Cline：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets Cline -Scope User
```

只装 Claude Code：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets ClaudeCode -Scope User
```

只装 Codex：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets Codex -Scope User
```

只装 Droid：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets Droid -Scope User
```

只装 OpenCode：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets OpenCode -Scope User
```

只装 CodeBuddy：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets CodeBuddy -Scope User
```

安装到某个项目：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets All -Scope Project -ProjectRoot E:\path\to\project
```

说明：

- Claude Code 现在按官方 `skills/` + `CLAUDE.md` 方式安装到 `.claude/skills` 和 `CLAUDE.md`。
- Codex 现在按原生 skills 方式安装到 `.agents/skills`，并写入 `AGENTS.md` 说明段。
- 对 Codex 要明确说明：linked worktree / detached HEAD 和受限 branch / push / PR 这些场景已经做了硬限制，正确行为是留在当前工作区或 commit + handoff，而不是假装上游流程完整跑通。
- OpenCode 现在按官方 `skill/*.md` 形式安装到 `.opencode/skill`。
- CodeBuddy 的项目级结构按官方公开文档实现；用户级 `~/.codebuddy` 路径是兼容性镜像写法。

## 对外更新说明

仓库更新后，用户可以直接：

```powershell
pwsh .\scripts\powershell\update-all.ps1 -Targets All -Scope User
```

如果用户自己不想先 `git pull`，`scripts/powershell/update-all.ps1` 会自动尝试更新当前仓库，然后重新安装。

说明：

- 这个命令会先提醒“接下来会覆盖已有 superpowers 安装”，用户确认后才继续
- 如果需要无人值守，可以加 `-AssumeYes`

如果维护者想把仓库内 vendored upstream 刷到新版本，再强制重装：

```powershell
pwsh .\scripts\powershell\refresh-upstream-and-reinstall.ps1 -Targets All -Scope User
```

这个命令也会先提醒即将覆盖已有 superpowers 安装；只有加了 `-AssumeYes` 才会跳过确认。

## GitHub Release 文案建议

如果这次发布包含 `Codex` 支持或 `Codex` 适配调整，建议在 release notes 里直接写出安全边界，例如：

- `Codex` 现在可以安全使用这套适配，但有些地方不会直接照搬上游 `Claude Code` 的默认做法。
- 遇到应用自己管理的 linked worktree / detached HEAD 时，不会再盲目新建 worktree。
- 遇到 sandbox 挡住 branch / push / PR 时，会改成 commit + handoff，而不是声称这些动作已经完成。

## 维护 vendored upstream

如果你要把仓库里的 `vendor/superpowers` 刷到最新 upstream：

```powershell
pwsh .\scripts\powershell\Refresh-VendoredSuperpowers.ps1
```

如果你已经本地改好了一个上游 checkout，也可以直接用本地源覆盖：

```powershell
pwsh .\scripts\powershell\Refresh-VendoredSuperpowers.ps1 -SourcePath E:\path\to\superpowers
```
