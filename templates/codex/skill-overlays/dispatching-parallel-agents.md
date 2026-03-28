Codex supports native subagents, but parallelism should still respect ownership boundaries.

- Prefer read-only investigation or isolated implementation slices instead of overlapping writes.
- Use focused subagents for research, review, or clearly partitioned code changes.
- Require each subagent to report touched files, validation results, documentation updates, and unresolved risks.
- Re-synthesize the combined result in the main thread before final validation.
