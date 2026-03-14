CodeBuddy can parallelize work, but the split should follow clean task boundaries.

- Use parallel tasks for isolated subsystems, research questions, or review passes.
- Ask each parallel worker to report changed files, validation results, and unresolved risks.
- Keep final consolidation, merge decisions, and release-facing validation in the main thread.
