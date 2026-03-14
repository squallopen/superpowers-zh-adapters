Translate upstream Claude Code references into Cline-native behaviors instead of following them literally.

- Treat `{{NAME_PREFIX}}brainstorming`, `{{NAME_PREFIX}}writing-plans`, `{{NAME_PREFIX}}executing-plans`, `{{NAME_PREFIX}}test-driven-development`, and `{{NAME_PREFIX}}systematic-debugging` as the core workflow set.
- When the task is exploratory, start with `{{NAME_PREFIX}}brainstorming` or Cline deep planning before committing to edits.
- When the task already has a clear direction, go straight to the matching implementation skill instead of forcing the full three-step chain.
- Use Focus Chain or an equivalent visible checklist when the upstream guidance mentions `TodoWrite`.
- Let `.clinerules` enforce default Simplified Chinese document output; do not translate code, identifiers, or logs unless the user explicitly asks.
