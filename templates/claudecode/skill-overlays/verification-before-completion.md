Treat verification as a hard completion gate, not a courtesy check.

- Separate what was verified, what failed, what was not run, and what residual risk remains.
- Prefer direct evidence: exact commands, exact tests, exact outputs, or exact manual checks.
- If a relevant verification step was not run, mark it `NOT RUN` instead of smoothing it over.
- If a relevant document or migration note still needs updating, mark it `BACKFILL REQUIRED`.
