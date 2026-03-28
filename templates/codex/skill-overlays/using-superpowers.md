Translate upstream Claude Code references into Codex-native behavior instead of following them literally.

- Use Codex native skills and subagents when a relevant skill might apply.
- When a skill references Claude Code's Task tool or named agent types, map that to Codex subagents and the instructions in `using-superpowers/references/codex-tools.md`.
- Let `AGENTS.md` carry the Chinese output policy; keep code and identifiers in their original language unless the user explicitly asks for translation.
