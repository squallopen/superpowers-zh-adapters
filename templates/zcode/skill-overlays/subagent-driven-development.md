Adapt subagent-driven development to ZCode without inventing unavailable tools.

- If ZCode can spawn isolated workers in the current environment, use them according to the skill's task boundaries and review checkpoints.
- If it cannot, fall back to `{{NAME_PREFIX}}executing-plans` style execution with explicit per-task verification and review notes.
- Keep task reports and final summaries in Simplified Chinese by default.
- Do not claim task reviewers ran unless their review actually ran and produced evidence.
