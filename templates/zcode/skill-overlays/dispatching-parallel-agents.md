Adapt parallel dispatch guidance to ZCode's current capabilities.

- Use ZCode's native parallel or subagent features only when they are actually available in the current session.
- If no such feature is available, split the work into independent slices and process them sequentially with clear checkpoints.
- Do not claim a subagent, reviewer, branch, push, or PR succeeded unless that action really happened.
- Summarize parallel findings in Simplified Chinese unless the user asks otherwise.
