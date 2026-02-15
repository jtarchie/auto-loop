# auto-loop

Run copilot commands across targets from stdin.

## Usage

```bash
<command> | ./auto-loop --model <model>[,model2,...] --prompt <prompt> [--validate <cmd>] [--group-pattern <regex>] [--after-group <cmd>] [-- <copilot-flags>]
```

Defaults to `--allow-all-tools --disallow-temp-dir --silent`. With `--validate`,
retries indefinitely until the validation command passes.

### Task Size Markers

Prefix tasks with `[S]`, `[M]`, `[L]`, or `[XL]` to control which model handles
them. Tasks without markers default to `[M]` (medium).

**Single model**: All sizes use the same model

```bash
echo "[L] Complex refactor" | ./auto-loop --model gpt-5 --prompt "Implement"
```

**Multiple models** (comma-separated): Models are distributed across sizes

```bash
# 2 models: S→first, M/L/XL→second
cat features.txt | ./auto-loop --model gpt-5-mini,gpt-5 --prompt "Build"

# 4 models: Perfect distribution
cat features.txt | ./auto-loop --model gpt-5-mini,gpt-5,gpt-5.2,gpt-5.2-codex --prompt "Build"
```

**Example task file**:

```
[S] Add GET /health endpoint
[M] Add user authentication with JWT
[L] Implement caching layer with Redis
[XL] Build distributed tracing system
Add basic logging (defaults to M)
```

### Grouped Processing

Use `--group-pattern` to group input lines by a regex. Lines matching the
pattern start a new group; subsequent lines belong to that group. Use
`--after-group` to run a command after each group completes.

```bash
cat tasks.md | ./auto-loop --model gpt-4 --prompt "Implement" --group-pattern '^\*\*.*:\*\*' --after-group "npm test"
```

## Examples

```bash
# Simple: one model, no size markers needed
find . -name "*.ts" | ./auto-loop --model gpt-4 --prompt "Fix the issue in"

# With validation and size marker
echo "[S] test.js" | ./auto-loop --model claude-sonnet --prompt "Write passing tests" --validate "npm test"

# Multiple models for cost optimization
cat features.txt | ./auto-loop --model gpt-5-mini,gpt-5.2 --prompt "Implement" --validate "npm test"

# Custom copilot flags
git diff --name-only HEAD~1 | ./auto-loop --model claude-sonnet --prompt "Refactor" -- --yolo
```

## Feature Development Workflow

A structured approach for building features using `auto-loop` with three files:

### File Structure

**`.todos.md`** - GitHub-style checklist with group headers matching
`--group-pattern`:

```markdown
**User Management:**

- [ ] [S] As a developer, I want a GET /users endpoint that returns an array of
      users, so that clients can retrieve the user list
- [ ] [M] As a developer, I want a POST /users endpoint to create new users, so
      that the system can add users to the database

**Authentication:**

- [ ] [L] As a user, I want to log in with email/password, so that I can access
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
cat .todos.md | ./auto-loop \
  --model gpt-5-mini,gpt-5 \
  --prompt "$(cat .prompt.md)" \
  --group-pattern '^\*\*.*:\*\*' \
  --after-group "$(cat .after-group.md)"
```

This pattern:

1. Implements tasks sequentially, using appropriate models based on size markers
2. After each group, reviews/refactors with a more powerful model
3. Groups related features for coherent review cycles
4. Optimizes costs by using smaller models for simpler tasks

**Template files** are available in `templates/` for quick setup. See
`.github/agents/feature-scaffolder.md` for the custom Feature Scaffolder agent
that generates these files from functional specifications.
