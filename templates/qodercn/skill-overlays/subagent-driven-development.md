Adapt subagent-driven development to Qoder CN without assuming Claude Code-specific task tools.

- Use Qoder CN's native delegation if it is available in the current session.
- If delegation is unavailable, preserve the same task boundaries and run them inline with explicit review checkpoints.
- Keep the main session responsible for integration, verification, and user-facing status.
