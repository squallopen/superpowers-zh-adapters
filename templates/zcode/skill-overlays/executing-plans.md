Adapt plan execution to ZCode's current capabilities.

- Treat the approved plan as authoritative, but verify the relevant repository context before editing.
- If ZCode has no separate subagent mechanism available in the current session, execute tasks in small checkpoints in the main session instead of pretending subagents ran.
- Keep status updates and handoff summaries in Simplified Chinese by default.
- After changes, run the narrowest meaningful verification first, then broader checks when the change touches shared behavior.
