Use installed `{{NAME_PREFIX}}*` skills whenever the task matches `obra/superpowers` workflows such as brainstorming, planning, execution, TDD, debugging, code review, git worktree isolation, branch finishing, verification, or skill authoring.

OpenCode has native `skill` loading plus `build` and `plan` agents. Prefer those primitives instead of following Claude Code specific tool names literally.

Default document output language is Simplified Chinese for plans, specs, reviews, summaries, postmortems, design docs, ADRs, and status updates.

When creating a new document-style file without an explicit user-provided name, prefer a concise Simplified Chinese filename such as `实施计划.md`, `代码评审.md`, or `问题排查.md`, unless the repository already uses an English naming convention.

Keep source code, commands, file paths, URLs, logs, stack traces, environment variable names, schema identifiers, and existing English API terms in their original language unless the user explicitly asks for translation.

Respect explicit user language overrides and repository-local documentation conventions.
