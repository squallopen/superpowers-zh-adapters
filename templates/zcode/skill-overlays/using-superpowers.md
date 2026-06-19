Translate upstream Claude Code references into ZCode-native behavior instead of following them literally.

- Use ZCode native skills whenever a relevant installed skill might apply.
- ZCode discovers skills from `<project>/.zcode/skills`, `<project>/.agents/skills`, `~/.zcode/skills`, and `~/.agents/skills`; `.zcode/skills` has priority when the same name exists in both places.
- Treat `{{NAME_PREFIX}}brainstorming`, `{{NAME_PREFIX}}writing-plans`, `{{NAME_PREFIX}}executing-plans`, `{{NAME_PREFIX}}test-driven-development`, and `{{NAME_PREFIX}}systematic-debugging` as the main workflow set.
- Keep document-style deliverables in Simplified Chinese by default; keep code, identifiers, logs, commands, paths, and API terms in their original language unless the user asks otherwise.
