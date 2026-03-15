# Superpowers 能力矩阵

这份矩阵只保留“大家最关心的那部分”：支持哪些宿主、用起来大概什么感觉、适合什么场景。

更细的宿主差异、示例 prompt 和直接点名 skill 的方式，都放到各宿主文档里。

## 宿主能力矩阵

| 宿主 | 14 个原版 skill | 中文触发 | 中文文档输出 | 多代理/并行理解 | 安装与更新安全 | 细节文档 |
| --- | --- | --- | --- | --- | --- | --- |
| `Cline` | 支持 | 支持 | 支持 | 更适合并行调研，主线程实施 | 专用 rule 文件，不覆盖其他规则 | [Cline 使用说明](cline-zh-prompts.md) |
| `Droid` | 支持 | 支持 | 支持 | 可拆独立工作面并行，主线程收口 | 只更新 `AGENTS.md` 专用说明段 | [Droid 使用说明](droid-zh-prompts.md) |
| `OpenCode` | 支持 | 支持 | 支持 | 可配合自己的 `plan` / `build` 能力 | 只更新 `AGENTS.md` 专用说明段 | [OpenCode 使用说明](opencode-zh-prompts.md) |
| `CodeBuddy` | 支持 | 支持 | 支持 | 更适合隔离面并行，主线程整合 | 只更新 `CODEBUDDY.md` 专用说明段 | [CodeBuddy 使用说明](codebuddy-zh-prompts.md) |

## Skill 速查

| Skill | 适合什么时候用 |
| --- | --- |
| `brainstorming` | 新需求刚来，先做需求分析、总体设计、详细设计、方案对比。 |
| `dispatching-parallel-agents` | 几个子任务互不依赖，想并行调研、并行推进。 |
| `executing-plans` | 计划已经定了，直接按计划往下做。 |
| `finishing-a-development-branch` | 功能做完准备收尾，判断提 PR、合并、保留还是丢弃。 |
| `receiving-code-review` | 已经收到了 review 意见，先判断哪些该改。 |
| `requesting-code-review` | 改动准备提交，想先做一次严格自查或代码评审。 |
| `subagent-driven-development` | 需求和计划已经比较清楚，想拆任务推进开发。 |
| `systematic-debugging` | 问题反复出现、原因不明，必须系统排查根因。 |
| `test-driven-development` | 新功能、修 bug、补回归，想先写失败测试。 |
| `using-git-worktrees` | 不想污染当前目录，想开隔离工作区。 |
| `using-superpowers` | 不确定该先分析、先写计划、先调试还是先 review。 |
| `verification-before-completion` | 准备说“做完了”之前，先跑验证、单元测试、集成测试和交付检查。 |
| `writing-plans` | 需求和方向已经比较清楚，下一步要写实施计划和任务拆解。 |
| `writing-skills` | 你不是在做业务功能，而是在写、改、验证 agent skill。 |

## 想看更详细的

- [中文使用总览](zh-cn-usage-guide.md)
- [Cline 使用说明](cline-zh-prompts.md)
- [Droid 使用说明](droid-zh-prompts.md)
- [OpenCode 使用说明](opencode-zh-prompts.md)
- [CodeBuddy 使用说明](codebuddy-zh-prompts.md)
- [自定义中文触发词](customize-triggers.md)
