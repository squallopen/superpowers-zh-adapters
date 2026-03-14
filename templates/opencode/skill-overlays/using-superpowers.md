Translate upstream Claude Code references into OpenCode-native behavior instead of following them literally.

- Treat `{{NAME_PREFIX}}brainstorming`, `{{NAME_PREFIX}}writing-plans`, `{{NAME_PREFIX}}executing-plans`, `{{NAME_PREFIX}}test-driven-development`, and `{{NAME_PREFIX}}systematic-debugging` as the main workflow set.
- Prefer the built-in `plan` agent for exploration and planning-heavy work, and the built-in `build` agent for implementation-heavy work.
- Use OpenCode's native `skill` loading whenever a relevant skill might apply.
- Let `AGENTS.md` carry the Chinese output policy; keep code and identifiers in their original language unless the user explicitly asks for translation.
