In this adapter, plans should stay implementation-ready and Chinese-readable at the same time.

- Preserve the upstream requirement that every task be concrete, buildable, and free of placeholders.
- When the input is a `TODO.md`, backlog, or worklist, keep the original order and only merge adjacent items when the first actionable item is too small to stand alone.
- Plans should explicitly call out affected files, data structures, interfaces, validation rules, tests, and rollback or risk notes when those matter.
- Unless the user explicitly requested English, write the plan body in Simplified Chinese while keeping code, commands, paths, and identifiers in their original language.
