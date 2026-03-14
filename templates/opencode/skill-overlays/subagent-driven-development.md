In OpenCode, use this workflow as plan-led execution with isolated subtasks.

1. Refine the plan first.
2. Dispatch subtasks only when the ownership boundary is clear.
3. Require each subtask to report touched files, validation results, and unresolved risks.
4. Reconcile the combined result in the main thread.
5. Run a final verification pass before claiming completion.

Avoid overlapping concurrent edits unless you have deliberately partitioned the change surface.
