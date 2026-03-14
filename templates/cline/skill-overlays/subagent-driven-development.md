In Cline, interpret this workflow as controller-led development with optional research delegates.

1. Build or refine the plan in the main thread.
2. Create a visible task list for the current slice of work.
3. Spawn subagents only to gather missing context, review a diff, compare approaches, or inspect unfamiliar modules.
4. Implement, test, and refactor in the main thread.
5. Use follow-up subagent passes for review findings, then apply fixes in the main thread.

Do not hand implementation ownership to subagents. If a task can only succeed through coordinated file edits, keep that entire loop in the main agent.
