# Qoder CN 中文使用说明

这页是给 `Qoder CN + superpowers` 用的。它讲的是本仓库的中文适配层怎么安装、怎么触发，不替代 Qoder CN 官方文档。

## 安装位置

默认安装名带 `superpowers-` 前缀，避免和 Qoder CN 自己或其他插件里的 skill 撞名。

User 模式会安装到：

```text
~/.qoder-cn/skills/<skill>/SKILL.md
```

Project 模式会安装到：

```text
<project>/.qoder/skills/<skill>/SKILL.md
```

User 模式会更新 `~/.qoder-cn/AGENTS.md` 里的 superpowers 专用说明段；Project 模式会更新 `<project>/AGENTS.md` 的专用说明段。脚本不会读写 Qoder CN 的登录态、凭据、模型配置或插件缓存。

## 安装命令

安装到当前用户：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets QoderCN -Scope User
```

安装到某个项目：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets QoderCN -Scope Project -ProjectRoot E:\path\to\project
```

已经装过，只更新 Qoder CN：

```powershell
pwsh .\scripts\powershell\update-all.ps1 -Targets QoderCN -Scope User
```

同步上游 `obra/superpowers` 后再重装 Qoder CN：

```powershell
pwsh .\scripts\powershell\refresh-upstream-and-reinstall.ps1 -Targets QoderCN -Scope User
```

## 常见触发方式

自然中文优先，例如：

- “先做需求分析和总体设计”
- “这个功能先写实施计划”
- “用 TDD 修这个 bug”
- “先做代码审查”
- “完成前先验证，不要急着说好了”
- “这次 superpowers 会话哪里出了问题，帮我诊断一下”

直接点名 skill 时，建议写完整安装名：

- `superpowers-brainstorming`
- `superpowers-writing-plans`
- `superpowers-test-driven-development`
- `superpowers-systematic-debugging`
- `superpowers-diagnosing-superpowers`
- `superpowers-verification-before-completion`

如果 Qoder CN 当前会话支持显式加载 skill，也优先使用完整名字。

## 和 Qwen Code 的关系

上游 `obra/superpowers` 在 `v6.4.2` 文档里新增了 Qwen Code 安装说明，但本仓库这次新增的是 Qoder CN 适配。两者不是同一个目标。

Qoder CN 这边走本地 skill 目录安装：

- User：`~/.qoder-cn/skills`
- Project：`<project>/.qoder/skills`

不建议手工改 Qoder CN 官方插件缓存目录。需要中文触发时，用本仓库脚本安装即可。
