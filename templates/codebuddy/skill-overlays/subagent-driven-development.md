Use this workflow as plan-driven delegated execution.

1. Confirm the plan first.
2. Use the tool's native text-search capability, or whatever retrieval method it judges best, then read the matching repository `README` sections, any relevant module or service `README` sections, the plan, and any referenced design, interface, data-structure, schema, Redis, S3, tech-stack, or other stack-specific passages before dispatching work. Keep that reading scoped to the current task, and do not read entire unrelated documents.
3. Split only independent work items.
4. Require each delegated task to report touched files, tests run, documentation updates, and remaining uncertainty.
5. Make unit tests part of the delegated work, and include integration tests too when they are feasible for the current change.
6. Reconcile the combined result in the main thread.
7. Backfill any affected docs and run final verification before claiming the work is complete.
8. In the final handoff, include a clear implementation summary with exact file paths: which files were added, which files were modified, which unit tests ran, which integration tests ran, what their pass rate or pass/total result was, and which docs were backfilled.
9. If a relevant test was not run, mark it `NOT RUN`. If anything failed, mark it clearly with `FAILED`. If a relevant document still needs updating, mark it `NOT BACKFILLED` or `BACKFILL REQUIRED`.
