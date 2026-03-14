In Cline, parallel agents are a research tool, not a write pipeline.

- Use `use_subagents` for codebase reconnaissance, option comparison, reproduction steps, dependency tracing, or review findings.
- Do not ask subagents to edit files, resolve merge conflicts, or own overlapping implementation tasks.
- Give each subagent a sharply bounded question, the exact files or subsystems to inspect, and a required return format.
- Consolidate the returned findings in the main thread, then perform edits and validation in the main agent.
- If the upstream plan assumes multiple agents coding in parallel, downgrade that to parallel investigation plus sequential main-agent execution.
