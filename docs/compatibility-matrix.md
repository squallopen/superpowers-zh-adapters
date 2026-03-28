# Superpowers 能力矩阵

这份矩阵只保留“大家最关心的那部分”：支持哪些工具、用起来大概什么感觉、适合什么场景。

更细的工具差异、示例 prompt 和直接点名 skill 的方式，都放到各自文档里。

## 工具能力矩阵

| 工具 | 14 个原版 skill | 中文触发 | 中文文档输出 | 多代理/并行理解 | 安装与更新安全 | 细节文档 |
| --- | --- | --- | --- | --- | --- | --- |
| `Cline` | 支持 | 支持 | 支持 | 更适合并行调研，主线程实施 | 专用 rule 文件，不覆盖其他规则 | [Cline 使用说明](cline-zh-prompts.md) |
| `Claude Code` | 支持 | 支持 | 支持 | 与上游最贴近，可直接按原生 workflow 跑 | 只更新 `CLAUDE.md` 专用说明段 | [Claude Code 使用说明](claude-code-zh-prompts.md) |
| `Codex` | 支持 | 支持 | 支持 | 可用原生 subagent，但 worktree / finishing 会按宿主能力硬降级 | 只更新 `AGENTS.md` 专用说明段，并对危险场景加硬限制 | [Codex 使用说明](codex-zh-prompts.md) |
| `Droid` | 支持 | 支持 | 支持 | 可拆独立工作面并行，主线程收口 | 只更新 `AGENTS.md` 专用说明段 | [Droid 使用说明](droid-zh-prompts.md) |
| `OpenCode` | 支持 | 支持 | 支持 | 可配合自己的 `plan` / `build` 能力 | 只更新 `AGENTS.md` 专用说明段 | [OpenCode 使用说明](opencode-zh-prompts.md) |
| `CodeBuddy` | 支持 | 支持 | 支持 | 更适合隔离面并行，主线程整合 | 只更新 `CODEBUDDY.md` 专用说明段 | [CodeBuddy 使用说明](codebuddy-zh-prompts.md) |

## Skill 速查

| Skill | 适合什么时候用 | 常见中文触发词 |
| --- | --- | --- |
| `brainstorming` | 需求还没聊清楚，先做需求分析、总体设计、详细设计、方案对比，把目标、边界和方向先讲明白。 | `需求分析`、`总体设计`、`详细设计`、`方案对比`、`先想清楚` |
| `dispatching-parallel-agents` | 几个子任务互不依赖，想并行调研、并行推进。 | `并行处理`、`多代理并行`、`拆给多个 agent` |
| `executing-plans` | 计划已经定了，直接按计划往下做。 | `执行计划`、`按计划做`、`照着计划实现` |
| `finishing-a-development-branch` | 功能做完准备收尾，判断提 PR、合并、保留还是丢弃。 | `开发收尾`、`准备提 PR`、`合并分支` |
| `receiving-code-review` | 已经收到了 review 意见，先判断哪些该改。 | `处理 review 意见`、`看 review 评论`、`修 review` |
| `requesting-code-review` | 改动准备提交，想先做一次严格自查或代码评审。 | `代码评审`、`帮我 review`、`提交前检查` |
| `subagent-driven-development` | 需求和计划已经比较清楚，想拆任务推进开发。 | `子代理开发`、`多 agent 开发`、`拆任务实现` |
| `systematic-debugging` | 问题反复出现、原因不明，必须系统排查根因。 | `系统排查`、`调 bug`、`定位问题`、`查根因` |
| `test-driven-development` | 新功能、修 bug、补回归，想先写失败测试。 | `TDD`、`测试先行`、`单元测试`、`先写测试` |
| `using-git-worktrees` | 不想污染当前目录，想开隔离工作区。 | `git worktree`、`隔离工作区`、`开新工作树` |
| `using-superpowers` | 不确定该先分析、先写计划、先调试还是先 review。 | `先选工作流`、`该用哪个 skill`、`按 superpowers 来` |
| `verification-before-completion` | 准备说“做完了”之前，先跑验证、单元测试、集成测试和交付检查。 | `完成前验证`、`集成测试`、`交付前检查`、`别急着说好了` |
| `writing-plans` | 需求和方向已经比较清楚，下一步直接写实施计划、接口设计、数据结构、表结构、Redis / S3 设计、字段说明、OpenAPI 骨架。 | `实施计划`、`接口设计`、`数据结构设计`、`redis设计`、`S3设计` |
| `writing-skills` | 你不是在做业务功能，而是在写、改、验证 agent skill。 | `写 skill`、`改 skill`、`更新 agent skill` |

完整触发词列表和自定义方式，看这里：

- [自定义中文触发词](customize-triggers.md)
- [data/zh-cn-skill-triggers.json](../data/zh-cn-skill-triggers.json)

## 想看更详细的

- [中文使用总览](zh-cn-usage-guide.md)
- [Cline 使用说明](cline-zh-prompts.md)
- [Claude Code 使用说明](claude-code-zh-prompts.md)
- [Codex 使用说明](codex-zh-prompts.md)
- [Droid 使用说明](droid-zh-prompts.md)
- [OpenCode 使用说明](opencode-zh-prompts.md)
- [CodeBuddy 使用说明](codebuddy-zh-prompts.md)
- [自定义中文触发词](customize-triggers.md)
