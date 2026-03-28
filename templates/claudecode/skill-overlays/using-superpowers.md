This adapter exists to add Chinese trigger hints and Chinese-first document defaults, not to rewrite Claude Code's native workflow semantics.

- In Claude Code, follow upstream superpowers tool usage directly.
- Prefer explicit `{{NAME_PREFIX}}...` skill names when disambiguation helps.
- Let `CLAUDE.md` carry the Chinese output policy; keep code and identifiers in their original language unless the user explicitly asks for translation.
