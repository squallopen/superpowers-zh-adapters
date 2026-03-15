# Superpowers 中文使用总览

这套适配不是把原版 skill 全部翻成中文，而是让你可以更自然地用中文把原版能力叫出来。

你可以把它理解成：

- skill 主体还是原版
- 触发方式更适合中文对话
- 文档型输出默认是中文
- 文档型文件默认优先放 `docs/`
- 文档说明默认尽量写得通俗易懂

## 默认文档落点和写法

如果 skill 需要新建计划、评审、设计说明、复盘这类文档，而你又没有指定路径和文件名，当前默认规则是：

- 优先放到 `docs/`
- 文件名优先用中文，例如 `实施计划.md`、`代码评审.md`、`问题排查.md`
- 正文默认用简体中文
- 代码、命令、路径、日志、接口名这类内容保留原文
- 技术术语尽量少堆，能用通俗中文讲清楚就先用通俗中文

## 触发 skill 的 3 种常见方式

### 1. 直接说自然中文

例如：

- “先做需求分析和总体设计”
- “先把这个需求拆成实施计划”
- “这个 bug 用 TDD 修”
- “先做代码审查”

这是最推荐的方式。

### 2. 直接点名 skill

默认安装名带前缀 `superpowers-`，所以直接点名时，建议写完整名字：

- `superpowers-brainstorming`
- `superpowers-writing-plans`
- `superpowers-systematic-debugging`
- `superpowers-finishing-a-development-branch`

### 3. 宿主支持 slash / command 形式时，直接调用

如果你的宿主支持 `/...` 这类形式，优先也写完整名字：

- `/superpowers-writing-plans`
- `/superpowers-finishing-a-development-branch`

注意：

- 默认安装下，不建议直接写 `/writing-plans`
- 默认安装下，也不建议直接写 `/finishing-a-development-branch`
- 只有你安装时显式用了 `-NamePrefix ''`，才更适合不带前缀的名字

## 一条最常见的工作流

```mermaid
flowchart LR
    A["using-superpowers"] --> B["brainstorming"]
    B --> C["writing-plans"]
    C --> D["executing-plans 或 subagent-driven-development"]
    D --> E["test-driven-development"]
    E --> F["requesting-code-review 或 receiving-code-review"]
    F --> G["verification-before-completion"]
    G --> H["finishing-a-development-branch"]
```

## 按宿主看更详细的用法

- [Cline 使用说明](cline-zh-prompts.md)
- [Droid 使用说明](droid-zh-prompts.md)
- [OpenCode 使用说明](opencode-zh-prompts.md)
- [CodeBuddy 使用说明](codebuddy-zh-prompts.md)

这些文档里会分别讲：

- 哪些说法更容易命中
- 哪些场景适合直接点名 skill
- 哪些场景适合并行，哪些更适合主线程收口

## 想自己改中文触发词

看这里：

- [自定义中文触发词](customize-triggers.md)

## 想先看能力速览

看这里：

- [简化版能力矩阵](compatibility-matrix.md)
