OpenCode supports specialized agents and subtasks, but parallelism should still respect ownership boundaries.

- Split work by subsystem, investigation question, or review surface so different agents do not compete on the same files.
- Use subagents for focused investigation, review, or isolated implementation slices.
- Re-synthesize findings in the main thread before broader edits or final validation.
- If an upstream workflow assumes many write-capable agents working on overlapping files, downgrade that to isolated subtasks plus main-thread integration.
