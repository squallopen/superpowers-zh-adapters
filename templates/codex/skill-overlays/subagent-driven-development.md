Use this workflow in Codex as orchestrated multi-agent execution.

1. Refine the plan first.
2. Use the tool's native text-search capability, or whatever retrieval method it judges best, then read the matching repository `README` sections, any relevant module or service `README` sections, the plan, and any referenced design, interface, data-structure, schema, Redis, S3, tech-stack, or other stack-specific passages before dispatching subtasks. Keep that reading scoped to the current task, and do not read entire unrelated documents.
3. Split ownership cleanly before dispatching any write-capable subagent.
4. When the skill refers to named reviewer agents, use the relevant prompt template with a Codex `worker` agent instead of assuming a plugin-managed named-agent registry.
5. Require every subagent to report touched files, tests run, documentation updates, and residual risks.
6. Reconcile and validate the combined result in the main thread.
7. If the current workspace is externally managed or detached HEAD, finish with a commit plus handoff guidance instead of pretending branch/push actions are available.
8. In the final handoff, include a clear implementation summary with exact file paths: which files were added, which files were modified, which unit tests ran, which integration tests ran, what their pass rate or pass/total result was, and which docs were backfilled.
9. If a relevant test was not run, mark it `NOT RUN`. If anything failed, mark it clearly with `FAILED`. If a relevant document still needs updating, mark it `NOT BACKFILLED` or `BACKFILL REQUIRED`.

Avoid overlapping concurrent edits unless you have deliberately partitioned the change surface.
