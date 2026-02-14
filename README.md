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

## Feature Development Workflow

A structured approach for building features using `auto-loop` with three files:

### File Structure

**`.todos.md`** - GitHub-style checklist with group headers matching
`--group-pattern`:

```markdown
**User Management:**

- [ ] As a developer, I want a GET /users endpoint that returns an array of
      users, so that clients can retrieve the user list
- [ ] As a developer, I want a POST /users endpoint to create new users, so that
      the system can add users to the database

**Authentication:**

- [ ] As a user, I want to log in with email/password, so that I can access
      protected resources
```

**`.prompt.md`** - Context prefix for each task (combined with stdin):

```markdown
In the Express app at examples/, implement:

Tech stack: Node.js, Express.js Patterns: RESTful APIs, middleware for auth Code
conventions: async/await, error handling middleware
```

**`.after-group.md`** - Cleanup command after each group:

```bash
copilot --model gpt-5 --prompt "Act as a senior engineer. Review recent changes in git diff for readability, maintainability, and scalability. Refactor if needed and update documentation."
```

### Running the Workflow

```bash
cat .todos.md | ./auto-loop.rb \
  --model gpt-5-mini \
  --prompt "$(cat .prompt.md)" \
  --group-pattern '^\*\*.*:\*\*' \
  --after-group "$(cat .after-group.md)"
```

This pattern:

1. Implements tasks sequentially with a lightweight model
2. After each group, reviews/refactors with a more powerful model
3. Groups related features for coherent review cycles

**Template files** are available in `templates/` for quick setup. See
`.github/agents/feature-scaffolder.md` for the custom Feature Scaffolder agent
that generates these files from functional specifications.
