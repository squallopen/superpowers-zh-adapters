Factory can delegate real work more naturally than Cline, but parallelism still needs boundaries.

- Split delegation by subsystem, ownership boundary, or investigation question to avoid overlapping file edits.
- Give each delegate a clear objective, expected output shape, and any file or directory constraints up front.
- Ask delegates to return changed files, unresolved risks, and validation results so the main thread can make the final call.
- Re-centralize the final integration, conflict resolution, and release-signoff steps in the main thread unless the task is already isolated.
