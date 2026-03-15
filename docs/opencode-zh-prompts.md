# OpenCode 使用说明

这份文档讲的是 `OpenCode + superpowers` 怎么更顺手地用。

相比 `Cline`，`OpenCode` 可以更自然地配合自己的 `plan` / `build` agent 使用。

## 在 OpenCode 里，superpowers 是怎么工作的

- 简单说：这里优先借 `OpenCode` 自己已经有的能力来承接 `superpowers` 的 workflow。
- 这句话的意思是：上游 `superpowers` 虽然是按 `Claude Code` 写的，但到了 `OpenCode` 这里，我们优先借 `OpenCode` 自己已经有的 `skill`、`plan`、`build` 这些能力来承接。
- 为什么这样：如果 `OpenCode` 自己已经有更顺手、更贴近本地使用习惯的实现，就没必要硬照抄上游那套工具名和动作名。
- 所以在 `OpenCode` 里，重点是保留上游 workflow 的意图，例如“先分析、再计划、再实现、再验证”，而不是强迫它模仿 `Claude Code` 的字面写法。
- 并行和分阶段推进也能做，但仍建议把最后整合、验收和收尾放主线程。

## 先记住 3 种触发方式

### 1. 自然中文说法

例如：

- “先做需求分析和总体设计”
- “把这个任务拆成几个工作面并行推进”
- “先跑完验证再说完成”

### 2. 直接点名 skill

默认安装名带前缀 `superpowers-`，所以建议写完整名字：

- `superpowers-writing-plans`
- `superpowers-dispatching-parallel-agents`
- `superpowers-finishing-a-development-branch`

### 3. 如果这个工具支持 slash / command 形式

也优先写完整名字：

- `/superpowers-writing-plans`
- `/superpowers-finishing-a-development-branch`

## OpenCode 最适合怎么理解

- `OpenCode` 有自己的 `plan` / `build` 能力，适合阶段拆分
- 但最终整合、验收和收尾，仍建议放在主线程

你可以把它理解成：

- 这里不是“降级”，而是优先用 `OpenCode` 自己更好的替代实现
- `superpowers` 负责告诉它该走什么 workflow
- `OpenCode` 自己的原生能力负责承接规划和实现动作

## 常用工作流

```mermaid
flowchart LR
    A["需求分析 / 方案讨论<br/>brainstorming"] --> B["实施计划<br/>writing-plans"]
    B --> C["按计划推进<br/>executing-plans / subagent-driven-development"]
    C --> D["代码评审<br/>requesting-code-review"]
    D --> E["收尾前验证<br/>verification-before-completion"]
    E --> F["开发分支收尾<br/>finishing-a-development-branch"]
```

## 启动工作流

```text
这件事按 superpowers 工作流来。你先判断当前阶段该用哪些 skill，再结合 OpenCode 自己的 plan / build 能力推进。
```

## 先讨论方案，再进入计划

```text
这个需求先不要直接实现。先做需求澄清、方案对比和边界讨论，结论用中文输出；如果方案收敛了，再继续拆实施计划。
```

## 直接写实施计划

```text
方向已经确定，直接把它拆成实施计划。步骤要具体到改哪些文件、怎么验证，中文输出。
```

## 按计划推进实现

```text
计划已经在上下文里了，按计划继续实现。能拆成独立工作面的部分再分阶段推进，但最后由主线程统一整合和验证。
```

## 并行推进

```text
把这个任务拆成几个互不冲突的工作面并行推进：接口、数据层、测试补充。每一块都要汇报改动文件、验证结果和剩余风险。
```

## Bug 排查

```text
这个问题先系统排查，不要先猜修复。先确认复现条件、缩小范围、收集证据，再决定怎么改。
```

## TDD 修复

```text
这个问题按 TDD 修。先写失败测试，确认失败后再做最小修复，最后再看是否需要重构。
```

## 请求代码审查

```text
这批改动先做一次严格代码审查，重点看行为回归、边界条件、缺失测试和计划偏差，结论用中文。
```

## 完成前验证

```text
先别说完成。先把验证清单跑完，把通过项、失败项和剩余风险分开写清楚，再决定是否可以收尾。
```

## OpenCode 使用要点

- OpenCode 的 `plan` / `build` 能力适合阶段拆分，但不要把最终整合和验收完全交出去。
- 文档型输出默认已经偏向中文；如果你特别在意，可以显式补一句“计划和结论用中文”。
- 代码、命令、路径、日志和接口名仍然建议保持原文。

## 想改中文触发词

- [自定义中文触发词](customize-triggers.md)
