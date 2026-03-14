# Superpowers 中文使用指南

这套适配保持 upstream `skill` 主体为英文，但默认让方案文档、计划、评审、总结等产出使用简体中文。

从结果上看，可以把它理解为“对整套 upstream skill 做了中文可用性适配”，但不是“把整套 skill 全文翻译成中文”。

补充示例：

- [Cline 中文示例 Prompt](cline-zh-prompts.md)
- [Droid 中文示例 Prompt](droid-zh-prompts.md)
- [OpenCode 中文示例 Prompt](opencode-zh-prompts.md)
- [CodeBuddy 中文示例 Prompt](codebuddy-zh-prompts.md)

## 核心工作流

### Cline

推荐顺序：

1. `superpowers-using-superpowers`
2. `superpowers-brainstorming`
3. `superpowers-using-git-worktrees`
4. `superpowers-writing-plans`
5. `superpowers-executing-plans` 或 `superpowers-subagent-driven-development`
6. `superpowers-test-driven-development`
7. `superpowers-requesting-code-review` 或 `superpowers-receiving-code-review`
8. `superpowers-verification-before-completion`
9. `superpowers-finishing-a-development-branch`

说明：

- 在 Cline 里，`subagent` 更适合调研、比选、代码库侦察，不适合把实现完全交出去。
- 所以 `dispatching-parallel-agents` 和 `subagent-driven-development` 在 Cline 中都按“并行调研 + 主线程实施”理解。

### Droid

推荐顺序：

1. `superpowers-using-superpowers`
2. `superpowers-brainstorming`
3. `superpowers-using-git-worktrees`
4. `superpowers-writing-plans`
5. `superpowers-subagent-driven-development` 或 `superpowers-executing-plans`
6. `superpowers-test-driven-development`
7. `superpowers-requesting-code-review` 或 `superpowers-receiving-code-review`
8. `superpowers-verification-before-completion`
9. `superpowers-finishing-a-development-branch`

说明：

- Droid 的任务委派能力比 Cline 更接近 upstream 预期，所以 `subagent-driven-development` 的适配幅度更小。
- 即便如此，最终整合、冲突处理和收尾验证仍建议放在主线程。

### OpenCode

推荐顺序：

1. `superpowers-using-superpowers`
2. `superpowers-brainstorming`
3. `superpowers-using-git-worktrees`
4. `superpowers-writing-plans`
5. `superpowers-subagent-driven-development` 或 `superpowers-executing-plans`
6. `superpowers-test-driven-development`
7. `superpowers-requesting-code-review` 或 `superpowers-receiving-code-review`
8. `superpowers-verification-before-completion`
9. `superpowers-finishing-a-development-branch`

说明：

- OpenCode 有自己的 `plan` / `build` agent，所以并行和阶段拆分能力比 Cline 更自然。
- 但 upstream skill 中提到的 Claude Code 专属工具名，仍然要按 OpenCode 原生能力理解，而不是字面照搬。

### CodeBuddy

推荐顺序：

1. `superpowers-using-superpowers`
2. `superpowers-brainstorming`
3. `superpowers-using-git-worktrees`
4. `superpowers-writing-plans`
5. `superpowers-executing-plans`
6. `superpowers-test-driven-development`
7. `superpowers-requesting-code-review` 或 `superpowers-receiving-code-review`
8. `superpowers-verification-before-completion`
9. `superpowers-finishing-a-development-branch`

说明：

- CodeBuddy 的项目级 skill 结构和 `CODEBUDDY.md` 规则很适合中文触发和中文文档输出。
- 对涉及多代理/多线程的 upstream skill，当前适配更保守，建议按“拆隔离面并行，主线程负责整合和验证”来理解。

## 中文触发速查

| Skill | 适用中文意图 | 常见中文说法 |
| --- | --- | --- |
| `superpowers-using-superpowers` | 先判断流程和该用哪个 skill | 先选工作流、该用哪个 skill、启用 superpowers、按 superpowers 来 |
| `superpowers-brainstorming` | 需求澄清、方案讨论、设计权衡 | 头脑风暴、想方案、需求澄清、设计讨论、方案对比 |
| `superpowers-writing-plans` | 编写实施计划和任务拆解 | 写计划、实施计划、拆步骤、任务拆解、施工计划 |
| `superpowers-executing-plans` | 按已有计划继续推进实现 | 执行计划、按计划做、照着计划实现、继续执行 |
| `superpowers-subagent-driven-development` | 把计划拆成可委派任务推进开发 | 子代理开发、多 agent 开发、拆任务实现、分 agent 做 |
| `superpowers-dispatching-parallel-agents` | 多任务并行推进 | 并行处理、拆给多个 agent、多代理并行、分头处理 |
| `superpowers-test-driven-development` | 测试先行、先写失败测试 | TDD、测试先行、先写测试、红绿重构 |
| `superpowers-systematic-debugging` | 系统排查 bug 和根因 | 系统排查、调 bug、定位问题、排障、查根因 |
| `superpowers-requesting-code-review` | 请求评审、提交前自查 | 帮我 review、请求代码审查、代码评审、提交前检查 |
| `superpowers-receiving-code-review` | 处理收到的 review 反馈 | 处理 review 意见、回应代码审查、修 review |
| `superpowers-verification-before-completion` | 完成前验证和最终确认 | 完成前验证、交付前检查、别急着说好了 |
| `superpowers-finishing-a-development-branch` | 分支收尾、提 PR、决定合并方式 | 开发收尾、结束这个分支、准备提 PR、合并分支 |
| `superpowers-using-git-worktrees` | 开隔离工作区 | git worktree、开新工作树、隔离工作区、新 worktree |
| `superpowers-writing-skills` | 编写和更新 skill | 写 skill、改 skill、做技能、验证 skill |

## 示例说法

### 规划类

- “这个需求先别写代码，先一起想方案和边界。”
- “先把这个需求拆成实施计划和可执行步骤。”

### 实现类

- “计划已经有了，按计划继续实现。”
- “按这个计划拆任务，让子代理分头开发。”

### 质量类

- “这个 bug 用 TDD 修，先写失败测试再改实现。”
- “这个测试偶发失败，先系统排查根因，不要直接猜修复。”
- “这个改动准备提交了，先帮我做一次代码审查。”

### 收尾类

- “先跑完验证再说修好了。”
- “这个功能做完了，帮我决定是提 PR、合并还是先保留分支。”
