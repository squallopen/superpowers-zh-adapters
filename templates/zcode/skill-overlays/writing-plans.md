Adapt this planning workflow to ZCode without assuming Claude Code-specific tools.

- Write durable plan, spec, review, and design documents in Simplified Chinese by default.
- If the user did not provide a path, prefer the repository documentation directory such as `docs/`, unless the repo clearly uses another convention.
- If the user did not provide a filename, prefer concise Chinese filenames such as `实施计划.md`, `接口设计.md`, `数据结构设计.md`, `Redis设计.md`, `S3设计.md`, or `字段说明.md` when they match the content.
- Keep source code, commands, paths, logs, API names, schema fields, and existing English identifiers in their original language.
- Capture interface contracts, data structures, field definitions, validation rules, naming conventions, retention rules, and error cases when they matter.
