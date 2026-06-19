# ZCode 中文使用说明

这页是给智谱 ZCode 用的。它讲的是本仓库的中文适配层怎么安装、怎么触发，不替代 ZCode 官方文档。

## 安装位置

默认安装名带 `superpowers-` 前缀，避免和 ZCode 官方插件市场里可能已经存在的 `superpowers` 插件撞名。

User 模式会安装到：

```text
~/.zcode/skills/<skill>/SKILL.md
```

Project 模式会安装到：

```text
<project>/.zcode/skills/<skill>/SKILL.md
```

ZCode 会优先发现 `.zcode/skills` 里的 skill。本适配不会修改 ZCode 的官方插件缓存，也不会读写 credentials、token、provider 配置这类敏感文件。

## 安装命令

安装到当前用户：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets ZCode -Scope User
```

安装到某个项目：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets ZCode -Scope Project -ProjectRoot E:\path\to\project
```

已经装过，只更新 ZCode：

```powershell
pwsh .\scripts\powershell\update-all.ps1 -Targets ZCode -Scope User
```

同步上游 `obra/superpowers` 后再重装 ZCode：

```powershell
pwsh .\scripts\powershell\refresh-upstream-and-reinstall.ps1 -Targets ZCode -Scope User
```

## 常见触发方式

自然中文优先，例如：

- “先做需求分析和总体设计”
- “这个功能先写实施计划”
- “用 TDD 修这个 bug”
- “先做代码审查”
- “完成前先验证，不要急着说好了”

直接点名 skill 时，建议写完整安装名：

- `superpowers-brainstorming`
- `superpowers-writing-plans`
- `superpowers-test-driven-development`
- `superpowers-systematic-debugging`
- `superpowers-verification-before-completion`

如果 ZCode 当前会话支持 `/skill <name>` 这类显式加载，也优先使用完整名字，例如：

```text
/skill superpowers-writing-plans 给这个接口补一版接口设计和字段说明
```

## 和官方 superpowers 插件的关系

ZCode 机器上可能已经安装过官方 `superpowers` 插件。这个仓库做的是中文适配版：

- 保留上游 skill 主体
- 给 description 追加中文触发词
- 给关键 skill 追加 ZCode 适配说明
- 记录 `.superpowers-install.json`，方便以后知道装的是哪个上游版本

不建议手工改 ZCode 官方插件缓存目录。需要中文触发时，用本仓库脚本安装到 `.zcode/skills` 即可。
