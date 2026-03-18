# Superpowers Bootstrap

Prefer installed `{{NAME_PREFIX}}*` skills when a request matches planning, execution, TDD, debugging, code review, git worktree isolation, branch finishing, verification, or skill-authoring workflows from `obra/superpowers`.

These skills were originally authored for Claude Code. Translate upstream references as follows:

- Claude skill invocation or slash-command workflow -> Cline skill invocation and built-in planning workflows
- `TodoWrite` -> Focus Chain or an equivalent task checklist that stays visible during execution
- `Task`, delegate, or subagent instructions -> Cline `use_subagents` for research, comparison, and codebase reconnaissance only
- File edits, implementation, and test execution -> keep these in the main Cline agent unless Cline later supports write-enabled subagents

When an upstream skill says `brainstorm -> write-plan -> execute-plan`, map that sequence to:

1. Use `{{NAME_PREFIX}}brainstorming` or Cline deep planning to explore options.
2. Use `{{NAME_PREFIX}}writing-plans` to produce the implementation plan.
3. Use `{{NAME_PREFIX}}executing-plans` to carry out the plan.

If an upstream workflow assumes write-capable subagents, downgrade that step to parallel investigation plus main-agent execution instead of skipping the workflow entirely.

When the user is still exploring requirements, constraints, trade-offs, overall design, or explicitly asks to think first, prefer `{{NAME_PREFIX}}brainstorming`.

When the user already wants a concrete document deliverable such as an implementation plan, interface design, request/response contract, data structure, table structure, Redis design, S3 design, field descriptions, or an OpenAPI-style skeleton, prefer `{{NAME_PREFIX}}writing-plans` directly. Only use `{{NAME_PREFIX}}brainstorming` first if key decisions are still unresolved.

If the user provides a `TODO.md`, backlog file, worklist, or similar task list and asks for a plan, treat that file as the requirement source. Preserve the list order, start from the first actionable item, and only expand forward when the first item is too small to form a reasonable standalone work slice.

If design or planning documents are produced, explicitly capture the relevant data structures, interface contracts, field definitions, validation rules, naming conventions, retention rules, and error cases when they matter to the task.
