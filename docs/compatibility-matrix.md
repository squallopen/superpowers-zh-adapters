# Superpowers 兼容矩阵

这份仓库不是重写 upstream skill，而是把 `obra/superpowers` 的 14 个真实 skill 接到不同宿主上，并补中文触发和中文文档输出策略。

## 状态说明

- `原生`：upstream 工作流和宿主能力基本直接对应。
- `适配`：需要通过规则、包装文件、overlay 或语言策略补一层。
- `降级`：仍可用，但 upstream 设想中的并行代理/委派能力会收缩。

## Skill 矩阵

| Upstream skill | 适合什么情况用 | Cline | Droid | OpenCode | CodeBuddy | 说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `brainstorming` | 新需求刚来，需求还模糊，先做需求分析、总体设计、详细设计时。 | 原生 | 原生 | 原生 | 原生 | 需求澄清、方案对比、设计权衡可直接复用。 |
| `dispatching-parallel-agents` | 几个子任务互不依赖，想并行调研、并行写草稿、并行做侦察时。 | 降级 | 适配 | 适配 | 降级 | Cline 更偏并行调研；OpenCode 可借助 `plan`/`build` agent；CodeBuddy 保守按“隔离面并行”理解。 |
| `executing-plans` | 计划已经写好，不想再讨论，直接按步骤往下做时。 | 原生 | 原生 | 原生 | 原生 | 已有计划后的执行流程在四宿主都可直接使用。 |
| `finishing-a-development-branch` | 功能做完准备收尾，想决定提 PR、合并、继续留分支还是补清理时。 | 原生 | 原生 | 原生 | 原生 | 分支收尾、PR 决策、合并策略都与宿主弱相关。 |
| `receiving-code-review` | 已经收到了 review 意见，想判断哪些该改、怎么改、哪些可以解释回去时。 | 原生 | 原生 | 原生 | 原生 | Review 反馈处理流程基本不依赖宿主特性。 |
| `requesting-code-review` | 改动准备提交，想先做一次代码评审、自查风险、找明显问题时。 | 原生 | 原生 | 原生 | 原生 | 请求审查、自查、整理结论的流程可直接复用。 |
| `subagent-driven-development` | 需求和计划已经比较清楚，想拆给多个 agent 分头实现再回主线程整合时。 | 降级 | 适配 | 适配 | 降级 | Cline/CodeBuddy 里最终仍建议主线程集成；Droid/OpenCode 更接近 upstream 的任务拆分预期。 |
| `systematic-debugging` | 问题反复出现、原因不明、日志混乱，不能靠猜，只能系统排查根因时。 | 原生 | 原生 | 原生 | 原生 | 系统排障、证据优先的流程宿主无关。 |
| `test-driven-development` | 新功能、修 bug、补回归时，想先写单元测试再写实现时。 | 原生 | 原生 | 原生 | 原生 | TDD 红绿重构循环可直接复用。 |
| `using-git-worktrees` | 这个需求不想污染当前目录，想开隔离工作区并行开发或实验时。 | 原生 | 原生 | 原生 | 原生 | Git worktree 操作和宿主绑定较弱。 |
| `using-superpowers` | 不确定现在该先分析、先写计划、先调试还是先 review，想先选工作流时。 | 适配 | 适配 | 适配 | 适配 | 都需要宿主级 bootstrap 说明、中文触发映射和 `superpowers-` 命名空间。 |
| `verification-before-completion` | 准备说“做完了”之前，想先跑单元测试、集成测试、构建和验收检查时。 | 原生 | 原生 | 原生 | 原生 | 完成前验证要求一致。 |
| `writing-plans` | 需求和方案差不多定了，下一步要写实施计划、任务拆解、开发步骤时。 | 原生 | 原生 | 原生 | 原生 | 写实施计划、拆步骤的模式通用。 |
| `writing-skills` | 你不是在做业务功能，而是在写、改、验证 agent skill 本身时。 | 适配 | 适配 | 适配 | 适配 | skill 编写方法能复用，但每个宿主的落盘结构不同。 |

## 安装行为

### `install-cline.ps1`

- 默认优先使用仓库里的 `vendor/superpowers`
- 安装到 `.cline/skills` 或 `~/.cline/skills`
- 从 upstream `SKILL.md` 生成 `prompt.md`
- 写入 `00-superpowers-bootstrap.md`
- 写入 `05-skill-triggers-zh-cn.md`
- 写入 `10-output-docs-zh-cn.md`

### `install-droid.ps1`

- 默认优先使用仓库里的 `vendor/superpowers`
- 安装到 `.factory/skills` 或 `~/.factory/skills`
- `Copy` 模式下可重写 `name:` 并扩展 `description:` 的中文触发提示
- 对 `using-superpowers`、`dispatching-parallel-agents`、`subagent-driven-development` 注入宿主 overlay
- 通过 `AGENTS.md` managed block 追加中文输出和中文触发规则

### `install-opencode.ps1`

- 默认优先使用仓库里的 `vendor/superpowers`
- 按官方 `skill/*.md` 形式安装到 `.opencode/skill` 或 `~/.config/opencode/skill`
- 每个 skill 生成一个 `superpowers-*.md` 入口文件
- 同名 companion 目录保留 upstream 的 `references/`、`scripts/` 与附带 markdown 资源
- 入口文件会把本地引用改写到 companion 目录，避免相对路径失效
- 通过 `AGENTS.md` managed block 追加中文输出和中文触发规则

### `install-codebuddy.ps1`

- 默认优先使用仓库里的 `vendor/superpowers`
- 项目级安装到 `.codebuddy/skills`
- 项目根写入 `CODEBUDDY.md` managed block
- 复制模式下会扩展 `description:` 的中文触发提示并追加 overlay
- 会写入 `.codebuddy/settings.json` 的 `language: 简体中文`
- 用户级 `~/.codebuddy` 路径属于兼容性镜像写法；官方公开文档主要覆盖项目级结构

## 有意不做的事

- 不伪造 Cline 的可写子代理能力。
- 不尝试把 upstream 的所有英文内容全文重写成中文。
- 不覆盖 managed block 之外的用户自定义说明文件内容。
