# auto-loop

Iteratively run copilot commands across a list of targets.

## Usage

```bash
./auto-loop.sh <model> <prompt> <command>
# or
<command> | ./auto-loop.sh <model> <prompt>
```

## Examples

```bash
./auto-loop.sh gpt-4 "Fix the issue in" "find src -name '*.ts'"
./auto-loop.sh claude-sonnet "Refactor" "git diff --name-only HEAD~1"
find . -name "*.ts" | ./auto-loop.sh gpt-4 "Add tests for"
cat files.txt | ./auto-loop.sh gpt-4 "Review"
rg -l 'slog\.' --type go | ./auto-loop.sh gpt-4 "Replace slog with zerolog in"
```

## Usage from Different Directories

```bash
# From any project directory, reference script by path
cd ~/projects/my-api
~/workspace/auto-loop/auto-loop.sh gpt-4 "Add error handling to" "find . -name '*.go'"

# Using absolute paths in the command itself
cd /tmp
~/workspace/auto-loop/auto-loop.sh gpt-4 "Refactor" "find ~/projects/webapp -name '*.tsx'"

# Mix relative finds with absolute script path
cd ~/projects/frontend
rg -l 'useState' | ~/workspace/auto-loop/auto-loop.sh claude-sonnet "Convert to useReducer in"
```
