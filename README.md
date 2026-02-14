# auto-loop

Run copilot commands across targets from stdin.

## Usage

```bash
<command> | ./auto-loop.rb --model <model> --prompt <prompt> [--validate <cmd>] [--group-pattern <regex>] [--after-group <cmd>] [-- <copilot-flags>]
```

Defaults to `--allow-all-tools --disallow-temp-dir --silent`. With `--validate`,
retries indefinitely until the validation command passes.

### Grouped Processing

Use `--group-pattern` to group input lines by a regex. Lines matching the
pattern start a new group; subsequent lines belong to that group. Use
`--after-group` to run a command after each group completes.

```bash
cat tasks.md | ./auto-loop.rb --model gpt-4 --prompt "Implement" --group-pattern '^\*\*.*:\*\*' --after-group "npm test"
```

## Examples

```bash
find . -name "*.ts" | ./auto-loop.rb --model gpt-4 --prompt "Fix the issue in"
echo "test.js" | ./auto-loop.rb --model claude-sonnet --prompt "Write passing tests" --validate "npm test"
git diff --name-only HEAD~1 | ./auto-loop.rb --model claude-sonnet --prompt "Refactor" -- --yolo
```
