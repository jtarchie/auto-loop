# auto-loop

Run copilot commands across targets from stdin.

## Usage

```bash
<command> | ./auto-loop.sh <model> <prompt> [-- <copilot-flags>]
<command> | ./auto-parallel.sh <model> <prompt> [--parallel N] [-- <copilot-flags>]
```

Both default to `--allow-all-tools --disallow-temp-dir --silent`.
`auto-parallel.sh` uses git worktrees in `.worktrees/` (reused across runs).

## Examples

```bash
find . -name "*.ts" | ./auto-loop.sh gpt-4 "Fix the issue in"
git diff --name-only HEAD~1 | ./auto-loop.sh claude-sonnet "Refactor" -- --yolo
cat features.md | ./auto-parallel.sh claude-sonnet-4.5 "Implement" --parallel 4 -- --agent task
```

## Worktree Management

After work completes, review changes in each worktree:

```bash
for w in .worktrees/worker-*; do git -C "$w" status; done
```

Merge changes back to main:

```bash
for w in .worktrees/worker-*; do git -C "$w" push origin HEAD; done
git pull
```

Clean up worktrees:

```bash
git worktree remove .worktrees/worker-*
rm -rf .worktrees/
```
