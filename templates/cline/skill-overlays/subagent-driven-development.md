In Cline, interpret this workflow as controller-led development with optional research delegates.

1. Build or refine the plan in the main thread.
2. Create a visible task list for the current slice of work.
3. Use the tool's native text-search capability, or whatever retrieval method it judges best, then read the matching repository `README` sections, any relevant module or service `README` sections, the plan, and any referenced design, interface, data-structure, schema, Redis, S3, tech-stack, or other stack-specific passages before implementation starts. Keep that reading scoped to the current task, and do not read entire unrelated documents.
4. Spawn subagents only to gather missing context, review a diff, compare approaches, or inspect unfamiliar modules.
5. Implement, test, and refactor in the main thread.
6. Add or update unit tests for the affected behavior, run integration tests when they are feasible, and backfill any affected docs before claiming completion.
7. Use follow-up subagent passes for review findings, then apply fixes in the main thread.
8. In the final handoff, include a clear implementation summary with exact file paths: which files were added, which files were modified, which unit tests ran, which integration tests ran, what their pass rate or pass/total result was, and which docs were backfilled.
9. If a relevant test was not run, mark it `NOT RUN`. If anything failed, mark it clearly with `FAILED`. If a relevant document still needs updating, mark it `NOT BACKFILLED` or `BACKFILL REQUIRED`.

Do not hand implementation ownership to subagents. If a task can only succeed through coordinated file edits, keep that entire loop in the main agent.
