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
