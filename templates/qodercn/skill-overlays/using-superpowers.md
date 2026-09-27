Translate upstream Claude Code references into Qoder CN-native behavior instead of following them literally.

- Use Qoder CN native skills whenever a relevant installed skill might apply.
- Qoder CN discovers project skills from `<project>/.qoder/skills` and user skills from `~/.qoder-cn/skills`.
- Let `AGENTS.md` carry durable Chinese output and workflow preferences.
- Treat `{{NAME_PREFIX}}brainstorming`, `{{NAME_PREFIX}}writing-plans`, `{{NAME_PREFIX}}executing-plans`, `{{NAME_PREFIX}}test-driven-development`, `{{NAME_PREFIX}}systematic-debugging`, and `{{NAME_PREFIX}}diagnosing-superpowers` as the main workflow set.
- Keep document-style deliverables in Simplified Chinese by default; keep code, identifiers, logs, commands, paths, and API terms in their original language unless the user asks otherwise.
