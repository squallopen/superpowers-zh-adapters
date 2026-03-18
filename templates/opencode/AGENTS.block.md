Use installed `{{NAME_PREFIX}}*` skills whenever the task matches `obra/superpowers` workflows such as brainstorming, planning, execution, TDD, debugging, code review, git worktree isolation, branch finishing, verification, or skill authoring.

OpenCode has native `skill` loading plus `build` and `plan` agents. Prefer those primitives instead of following Claude Code specific tool names literally.

Default document output language is Simplified Chinese for plans, specs, reviews, summaries, postmortems, design docs, ADRs, and status updates.

When creating a new durable document-style file without an explicit user-provided path, prefer the repository's documentation directory. Use `docs/` by default, unless the repository already clearly uses another documentation directory such as `doc/`, `spec/`, or `specs/`.

When creating a new document-style file without an explicit user-provided name, prefer a concise Simplified Chinese filename that matches the document's actual purpose, such as `实施计划.md`, `代码评审.md`, `问题排查.md`, `接口设计.md`, `数据结构设计.md`, `表结构设计.md`, `Redis设计.md`, `S3设计.md`, or `字段说明.md`, unless the repository already uses an English naming convention.

If the document is specifically about Redis or S3, prefer literal names like `Redis设计.md` and `S3设计.md` over broader names such as cache design or object storage design.

Write document content in Simplified Chinese and keep it direct, concrete, and easy for Chinese-speaking teammates to read. Prefer plain language over heavy jargon. If a technical term is necessary, keep it accurate and add a brief explanation when that helps readability.

Keep source code, commands, file paths, URLs, logs, stack traces, environment variable names, schema identifiers, and existing English API terms in their original language unless the user explicitly asks for translation.

When the user is still exploring requirements, constraints, trade-offs, overall design, or explicitly asks to think first, prefer `{{NAME_PREFIX}}brainstorming`.

When the user already wants a concrete document deliverable such as an implementation plan, interface design, request/response contract, data structure, table structure, Redis design, S3 design, field descriptions, or an OpenAPI-style skeleton, prefer `{{NAME_PREFIX}}writing-plans` directly. Only use `{{NAME_PREFIX}}brainstorming` first if key decisions are still unresolved.

If the user provides a `TODO.md`, backlog file, worklist, or similar task list and asks for a plan, treat that file as the requirement source. Preserve the list order, start from the first actionable item, and only expand forward when the first item is too small to form a reasonable standalone work slice.

If design or planning documents are produced, explicitly capture the relevant data structures, interface contracts, field definitions, validation rules, naming conventions, retention rules, and error cases when they matter to the task.

Respect explicit user language overrides and repository-local documentation conventions.
