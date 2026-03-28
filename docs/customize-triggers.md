# 自定义中文触发词

如果你想改“哪些中文说法会触发哪些 skill”，只需要改一个文件：

- [data/zh-cn-skill-triggers.json](../data/zh-cn-skill-triggers.json)

## 这个文件怎么读

每一项对应一个原版 skill。

例子：

```json
{
  "name": "brainstorming",
  "summary_zh": "需求分析、方案澄清、总体设计、详细设计",
  "phrases": ["头脑风暴", "想方案", "需求分析", "需求澄清", "总体设计", "详细设计"],
  "example_cn": "这个功能先别急着写，先把需求、边界和方案想清楚。"
}
```

字段含义：

- `name`
  原版 skill 名，不要随便改
- `summary_zh`
  这个 skill 适合干什么的中文摘要
- `phrases`
  你希望命中的中文说法
- `example_cn`
  一句典型中文示例，方便以后维护时看懂

## 什么时候该改

常见场景：

- 你们团队平时不用“写计划”，而是说“出实施方案”
- 你们习惯说“单元测试”或“集成测试”，想更稳地命中验证类 skill
- 你们习惯说“需求分析 / 总体设计 / 详细设计”，想更稳地命中 `brainstorming`
- 你们习惯说“接口设计 / 数据结构设计 / Redis设计 / S3设计”，想更稳地命中 `writing-plans`
- 你想补自己的口头禅，比如“先别写代码”“先过一遍改动”

## 改的时候注意什么

- `name` 最好保持和原版 skill 一致
- `phrases` 不要堆太多意思相近的词，够用就行
- 优先放你们团队真实会说的话
- 可以按“先想清楚”和“直接出文档”两类来分，别把所有设计类词都堆进 `brainstorming`
- 如果原版仓库新增了 skill，记得补一条新的映射

## 改完后怎么生效

改完 JSON 后，重新安装一次就行：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets All -Scope User
```

如果你只想刷新某一个工具：

```powershell
pwsh .\scripts\powershell\install-all.ps1 -Targets Cline -Scope User
```

如果你还改了输出规则，比如想把默认文档目录从 `docs/` 改成别的地方，记得同时调整这些模板：

- [templates/cline/rules/10-output-docs-zh-cn.md](../templates/cline/rules/10-output-docs-zh-cn.md)
- [templates/claudecode/CLAUDE.block.md](../templates/claudecode/CLAUDE.block.md)
- [templates/codex/AGENTS.block.md](../templates/codex/AGENTS.block.md)
- [templates/droid/AGENTS.block.md](../templates/droid/AGENTS.block.md)
- [templates/opencode/AGENTS.block.md](../templates/opencode/AGENTS.block.md)
- [templates/codebuddy/CODEBUDDY.block.md](../templates/codebuddy/CODEBUDDY.block.md)

## 除了自然中文，还可以怎么触发

默认安装名带前缀 `superpowers-`，所以直接点名 skill 时，建议写完整名字：

- `superpowers-writing-plans`
- `superpowers-systematic-debugging`
- `superpowers-finishing-a-development-branch`

如果这个工具支持 slash / command 形式，也优先写完整名字：

- `/superpowers-writing-plans`
- `/superpowers-finishing-a-development-branch`

只有你安装时显式用了 `-NamePrefix ''`，才适合写不带前缀的形式，比如：

- `/writing-plans`
- `/finishing-a-development-branch`
