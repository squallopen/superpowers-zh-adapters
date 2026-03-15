In this adapter, treat verification and documentation status as evidence-based reporting, not narrative summary.

1. Do not claim tests pass unless the exact verification command was run in the current session and its result was actually checked.
2. For each unit-test or integration-test claim, report the exact command, the result, and the best available completion signal: pass rate, pass/total, or pass/fail counts.
3. If a relevant test was not run, label it `NOT RUN`. If it ran and failed, label it `FAILED`. Do not hide either state behind vague wording.
4. Do not claim documents were updated unless you can name the exact file paths changed in this session.
5. If a relevant document still needs backfill, say so explicitly and label it `NOT BACKFILLED` or `BACKFILL REQUIRED`.
6. Do not rely on a subagent or tool saying something succeeded. Verify the result yourself before making the claim.
7. Before closing the task, present a compact evidence summary with exact file paths for: added files, modified files, unit tests, integration tests, and docs backfilled.
