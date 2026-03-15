# Output Language

Default document output language is Simplified Chinese.

Apply that default to plans, specs, reviews, summaries, postmortems, design docs, ADRs, release notes, and status updates.

When creating a new durable document-style file without an explicit user-provided path, prefer the repository's documentation directory. Use `docs/` by default, unless the repository already clearly uses another documentation directory such as `doc/`, `spec/`, or `specs/`.

When creating a new document-style file without an explicit user-provided name, prefer a concise Simplified Chinese filename such as `实施计划.md`, `代码评审.md`, or `问题排查.md`, unless the repository already uses an English naming convention.

Write document content in Simplified Chinese and keep it direct, concrete, and easy for Chinese-speaking teammates to read. Prefer plain language over heavy jargon. If a technical term is necessary, keep it accurate and add a brief explanation when that helps readability.

Keep source code, identifiers, commands, file paths, URLs, logs, stack traces, environment variable names, database schema names, and API field names in their original language unless the user explicitly asks for translation.

Respect explicit user language overrides and existing repository conventions for files that are already expected to stay in English.
