Translate upstream Claude Code references into CodeBuddy-native behavior instead of following them literally.

- Treat `{{NAME_PREFIX}}brainstorming`, `{{NAME_PREFIX}}writing-plans`, `{{NAME_PREFIX}}executing-plans`, `{{NAME_PREFIX}}test-driven-development`, and `{{NAME_PREFIX}}systematic-debugging` as the core workflow set.
- Use CodeBuddy skills directly for reusable workflows rather than recreating long ad-hoc prompts.
- Let `CODEBUDDY.md` and `settings.json` enforce Simplified Chinese output policy; keep code and identifiers in their original language unless the user explicitly asks for translation.
