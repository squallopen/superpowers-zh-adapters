When producing an implementation plan in this adapter, make the execution prerequisites explicit.

If the user provides a `TODO.md`, backlog file, worklist, or similar task list as the requirement source, do not ask them to restate the feature by default.

Use this scope-selection rule instead:
1. Preserve the task order from the provided list.
2. Start from the first actionable item that is not already done, blocked, or explicitly out of scope.
3. If that item is too small for a meaningful standalone implementation plan, expand forward to the immediately following items that belong to the same topic, dependency chain, or delivery goal until the scope becomes a reasonable work slice.
4. Do not skip ahead to later items unless earlier items are already done, clearly blocked, or the user explicitly asks for a different slice.
5. Only ask the user to clarify the target when the list is empty, too ambiguous to group safely, or contains multiple equally plausible starting slices.

If the user specifies where the plan should be saved, use that location. Do not force a fixed plan directory. If no path is specified, prefer the repository's existing documentation convention; only choose a new sensible documentation location when no clear convention exists, and state the chosen path explicitly in the handoff.

1. Add a short "read before coding" list when the task depends on existing documents. Keep that list scoped to the current task. Prefer the tool's native text-search capability, or whatever retrieval method it judges best, then read only the matching `README` sections plus the relevant plan, design, interface, data-structure, schema, Redis, S3, tech-stack, or operational passages rather than entire unrelated documents. It should start with the repository `README` and any relevant module or service `README`, then include design specs, implementation notes, interface design, data structure or schema notes, Redis design, S3 design, tech stack notes, or operational instructions.
2. For each implementation slice, include explicit unit-test work. Do not leave tests as an implied follow-up.
3. If the change crosses module, API, storage, or workflow boundaries and integration testing is feasible in this repository, include an integration-test task or explicitly state why it is not practical.
4. If the implementation will change documented behavior, interfaces, fields, examples, deployment notes, or operating steps, include explicit documentation backfill tasks.
5. Make the verification and documentation steps concrete enough that `{{NAME_PREFIX}}executing-plans` can follow them without guessing.
