When this skill asks for a `general-purpose` code reviewer subagent, use a Codex `worker` agent with the referenced reviewer prompt template.

- Use `requesting-code-review/code-reviewer.md` as the worker's message body.
- Fill placeholders with exact SHAs, requirements, and implementation summary before dispatch.
- Keep the reviewer focused on the diff or work product, not on full session history.
