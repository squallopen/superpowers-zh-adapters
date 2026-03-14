Translate upstream Claude Code references into Factory-native primitives instead of following them literally.

- Treat `{{NAME_PREFIX}}brainstorming`, `{{NAME_PREFIX}}writing-plans`, `{{NAME_PREFIX}}executing-plans`, `{{NAME_PREFIX}}test-driven-development`, and `{{NAME_PREFIX}}systematic-debugging` as the default workflow set.
- Use skills first, then layer project or user `AGENTS.md` guidance on top.
- When the task is already well scoped, skip directly to the matching implementation skill instead of forcing the full planning chain.
- Keep document-style deliverables in Simplified Chinese by default; keep code, identifiers, logs, and API terms in their original language unless the user asks otherwise.
