Use this workflow as delegated implementation with strong orchestration.

1. Define the plan and slice boundaries in the main thread.
2. Use the tool's native text-search capability, or whatever retrieval method it judges best, then read the matching repository `README` sections, any relevant module or service `README` sections, the plan, and any referenced design, interface, data-structure, schema, Redis, S3, tech-stack, or other stack-specific passages before delegation starts. Keep that reading scoped to the current task, and do not read entire unrelated documents.
3. Delegate isolated work items when the ownership boundary is clear.
4. Require each delegate to report files touched, tests run, documentation updates, and known uncertainties.
5. Make unit tests part of the delegated work, and add or run integration tests too when they are feasible for the current change.
6. Run a separate review pass when the change is risky or the spec is tight.
7. Merge, reconcile, backfill any affected docs, and validate the complete result in the main thread.
8. In the final handoff, include a clear implementation summary with exact file paths: which files were added, which files were modified, which unit tests ran, which integration tests ran, what their pass rate or pass/total result was, and which docs were backfilled.
9. If a relevant test was not run, mark it `NOT RUN`. If anything failed, mark it clearly with `FAILED`. If a relevant document still needs updating, mark it `NOT BACKFILLED` or `BACKFILL REQUIRED`.

Avoid concurrent delegates on the same files unless you have explicitly partitioned the edit surface.
