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

常见结果大概会像这样：

```text
docs/
  需求分析.md
  总体设计.md
  详细设计.md
  实施计划.md
  代码评审.md
```

如果你已经明确说了路径或文件名，例如“把计划写到 `specs/iteration-2-plan.md`”，那就优先按你的要求来，不会强行改成中文名。

## 触发 skill 的 3 种常见方式

### 1. 直接说自然中文

例如：

- “先做需求分析和总体设计”
- “补一版详细设计”
- “先把这个需求拆成实施计划”
- “这个 bug 用 TDD 修”
- “先补单元测试和集成测试”
- “先做代码审查”

这是最推荐的方式。

### 2. 直接点名 skill

默认安装名带前缀 `superpowers-`，所以直接点名时，建议写完整名字：

- `superpowers-brainstorming`
- `superpowers-writing-plans`
- `superpowers-systematic-debugging`
- `superpowers-finishing-a-development-branch`

### 3. 如果你用的工具支持 slash / command，直接调用

如果你用的工具支持 `/...` 这类形式，优先也写完整名字：

- `/superpowers-writing-plans`
- `/superpowers-finishing-a-development-branch`

注意：

- 默认安装下，不建议直接写 `/writing-plans`
- 默认安装下，也不建议直接写 `/finishing-a-development-branch`
- 只有你安装时显式用了 `-NamePrefix ''`，才更适合不带前缀的名字

## 一条最常见的工作流

```mermaid
flowchart LR
    A["先选工作流<br/>using-superpowers"] --> B["需求分析 / 方案澄清<br/>brainstorming"]
    B --> C["实施计划<br/>writing-plans"]
    C --> D["按计划推进<br/>executing-plans / subagent-driven-development"]
    D --> E["测试先行<br/>test-driven-development"]
    E --> F["代码评审<br/>requesting-code-review / receiving-code-review"]
    F --> G["收尾前验证<br/>verification-before-completion"]
    G --> H["开发分支收尾<br/>finishing-a-development-branch"]
```

## 按工具看更详细的用法

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
