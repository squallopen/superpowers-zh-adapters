# 发布到 GitHub

这份仓库现在已经基本是“可发布”状态，但真正发到 GitHub 还需要你做两件事：

1. 确定仓库名、可见性和顶层许可证
2. 绑定你自己的 GitHub remote 并 push

## 发布前检查

- 确认 `vendor/superpowers` 只是普通文件目录，不再带自己的 `.git`
- 确认 [README.md](../README.md)、[docs/compatibility-matrix.md](compatibility-matrix.md)、[docs/zh-cn-usage-guide.md](zh-cn-usage-guide.md) 内容符合你想公开的描述
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

- OpenCode 现在按官方 `skill/*.md` 形式安装到 `.opencode/skill`。
- CodeBuddy 的项目级结构按官方公开文档实现；用户级 `~/.codebuddy` 路径是兼容性镜像写法。

## 对外更新说明

仓库更新后，用户可以直接：

```powershell
pwsh .\scripts\powershell\update-all.ps1 -Targets All -Scope User
```

如果用户自己不想先 `git pull`，`scripts/powershell/update-all.ps1` 会自动尝试更新当前仓库，然后重新安装。

如果维护者想把仓库内 vendored upstream 刷到新版本，再强制重装：

```powershell
pwsh .\scripts\powershell\refresh-upstream-and-reinstall.ps1 -Targets All -Scope User
```

## 维护 vendored upstream

如果你要把仓库里的 `vendor/superpowers` 刷到最新 upstream：

```powershell
pwsh .\scripts\powershell\Refresh-VendoredSuperpowers.ps1
```

如果你已经本地改好了一个上游 checkout，也可以直接用本地源覆盖：

```powershell
pwsh .\scripts\powershell\Refresh-VendoredSuperpowers.ps1 -SourcePath E:\path\to\superpowers
```
