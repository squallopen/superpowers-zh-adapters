When executing a plan in Codex, keep the plan authoritative and treat reading, testing, and backfill as first-class work.

1. Before the first code edit, use the tool's native text-search capability, or whatever retrieval method it judges best, then read the matching repository `README` sections, any relevant module or service `README` sections, the implementation plan, and any referenced spec, design, interface, data-structure, schema, Redis, S3, tech-stack, or operational passages. Keep that reading scoped to the current task, and do not read entire unrelated documents.
2. If the plan assumes a document exists but it is missing, stale, or contradictory, stop and raise that issue before continuing.
3. After code changes, add or update unit tests for the affected behavior. Do not skip this unless the user has explicitly accepted the gap.
4. If the change crosses service, API, storage, or workflow boundaries and integration testing is feasible in the current repository, run or add integration tests too. If it is not feasible, say why.
5. If the current environment blocks branch or push operations, still finish the implementation cleanly: stage or commit as needed, report exact limitations, and hand off with concrete next-step instructions.
6. In the final handoff, include a clear implementation summary with exact file paths: which files were added, which files were modified, which documents you read, which documents you backfilled, which unit tests ran, which integration tests ran, and how they performed.
