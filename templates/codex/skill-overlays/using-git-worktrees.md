In Codex, the current workspace may already be a linked worktree managed by the host application.

- Before creating a worktree, compare `git rev-parse --git-dir` with `git rev-parse --git-common-dir`, and inspect the current branch state.
- If you are already inside a linked worktree, skip worktree creation and run setup plus baseline verification in the current directory.
- If `git worktree add -b` fails because the sandbox blocks ref updates, fall back to the current directory and report that you are using the existing workspace as the isolated surface.
- Never claim you created a new worktree if you stayed in place; say exactly which directory is being used.
