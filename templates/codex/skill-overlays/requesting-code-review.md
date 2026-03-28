When this skill asks for `superpowers:code-reviewer`, Codex should treat that as a prompt-driven worker, not as a built-in named agent.

- Use `agents/code-reviewer.md` or the referenced reviewer prompt template as the worker's message body.
- Fill placeholders with exact SHAs, requirements, and implementation summary before dispatch.
- Keep the reviewer focused on the diff or work product, not on full session history.
