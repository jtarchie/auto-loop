# auto-loop

Iteratively run copilot commands across a list of targets.

## Usage

```bash
<command> | ./auto-loop.sh <model> <prompt> [-- <copilot-flags>]
```

Reads targets from stdin, running copilot for each. Always runs with `--silent`.
Defaults to `--allow-all-tools --disallow-temp-dir` if no flags provided.

## Examples

```bash
# Basic usage
find . -name "*.ts" | ./auto-loop.sh gpt-4 "Fix the issue in"
git diff --name-only HEAD~1 | ./auto-loop.sh claude-sonnet "Refactor"
rg -l 'slog\.' --type go | ./auto-loop.sh gpt-4 "Replace slog with zerolog in"

# With custom copilot flags
find . -name "*.go" | ./auto-loop.sh gpt-4 "Add tests for" -- --yolo
cat files.txt | ./auto-loop.sh claude-sonnet "Review" -- --agent
```

## Usage from Different Directories

```bash
# From any project directory
cd ~/projects/my-api
find . -name "*.go" | ~/workspace/auto-loop/auto-loop.sh gpt-4 "Add error handling to"

# Using absolute paths
cd /tmp
find ~/projects/webapp -name "*.tsx" | ~/workspace/auto-loop/auto-loop.sh gpt-4 "Refactor"

# Mix relative finds with absolute script path
cd ~/projects/frontend
rg -l 'useState' | ~/workspace/auto-loop/auto-loop.sh claude-sonnet "Convert to useReducer in"
```
