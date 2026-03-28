Finishing a branch in Codex may differ from upstream when the workspace is externally managed.

- Re-detect `git-dir`, `git-common-dir`, and current branch state before presenting merge or push options.
- If you are in a linked worktree on detached HEAD, do not offer local merge, push, or PR creation as if they are available.
- Commit the finished work, report the exact commit SHA, suggest a branch name and commit message, and tell the user to use the host application's native branch or local-handoff controls.
- Only remove worktrees that this workflow created itself. Externally managed worktrees belong to the host environment.
