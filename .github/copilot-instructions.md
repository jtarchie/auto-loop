# Copilot Agent Instructions for auto-loop

## Repository Overview

This repository provides **bash wrapper scripts** for running GitHub Copilot CLI
commands in batch mode across multiple targets. It's a small utility project (<
100 lines of shell script) designed to automate copilot tasks over lists of
files, features, or other inputs.

**Design Philosophy**: Shell scripts must be **minimal and succinct**. Keep code
terse, avoid unnecessary complexity, and prioritize readability through brevity.

**Type**: Shell utility scripts\
**Size**: Minimal (3 shell scripts + 1 example Node.js app)\
**Languages**: Bash (primary), JavaScript (examples only)\
**Target Runtime**: Bash 5.x+, GitHub Copilot CLI 0.0.392+\
**Purpose**: Automate copilot CLI invocations with parallel execution support
via git worktrees

## Core Architecture

### Main Scripts (Root Directory)

1. **`auto-loop.sh`** (264 bytes)
   - Sequential processor: pipes stdin lines → copilot CLI invocations
   - Usage: `<command> | ./auto-loop.sh <model> <prompt> [-- <copilot-flags>]`
   - Exits on first failure (`exit 1`)
   - Defaults: `--allow-all-tools --disallow-temp-dir --silent`

2. **`auto-parallel.sh`** (768 bytes)
   - Parallel processor: uses git worktrees for isolated concurrent execution
   - Usage:
     `<command> | ./auto-parallel.sh <model> <prompt> [--parallel N] [-- <copilot-flags>]`
   - Creates worktrees in `.worktrees/worker-<N>/` (reused across runs)
   - Uses `nl` for line numbering, `xargs -P` for parallelization
   - Instructs copilot to commit changes via:
     `git add -A && git commit -m <message>`
   - Continues on error (`: operator` at end of copilot invocation)

3. **`tests.sh`** (1106 bytes)
   - Integration test: sets up temp environment, runs auto-parallel.sh
   - Timeout: 180 seconds
   - Requires npm for examples/ dependencies

### Examples Directory

- **`examples/index.js`**: Basic Express.js server (15 lines, port 3000)
- **`examples/package.json`**: Dependencies: `express@^4.18.0`
- **`examples/features.txt`**: 5-line feature list for testing parallel
  additions
- **Purpose**: Demonstrates auto-parallel.sh by implementing Express endpoints

### Configuration

- **`.gitignore`**: Excludes `.worktrees/` directory only
- **Shell linting**: shellcheck 0.11.0+ required for all shell script changes
- **Shell formatting**: shfmt 3.12.0+ required for all shell script changes
- **No CI/CD configured**

## Environment Requirements

### ALWAYS Install These First

1. **Bash 5.3.9+** (GNU bash required)
   - Verify: `bash --version`
   - macOS: Install via `brew install bash`

2. **GitHub Copilot CLI 0.0.392+**
   - Verify: `copilot --version`
   - Must be authenticated and configured

3. **Git 2.50+** with worktree support
   - Verify: `git --version`

4. **Standard Unix utilities** (usually pre-installed):
   - `xargs`, `timeout`, `nl`
   - Verify: `which xargs timeout nl`

5. **Node.js 25.4.0+ and npm 11.7.0+** (for examples/ only)
   - Verify: `node --version && npm --version`
   - Only needed if working with the examples directory

6. **shellcheck 0.11.0+** (REQUIRED for shell script modifications)
   - Verify: `shellcheck --version`
   - macOS: Install via `brew install shellcheck`
   - ALWAYS run on modified shell scripts before committing

7. **shfmt 3.12.0+** (REQUIRED for shell script modifications)
   - Verify: `shfmt --version`
   - macOS: Install via `brew install shfmt`
   - ALWAYS run on modified shell scripts before committing

## Build, Test, and Run Commands

### Sequential Execution (auto-loop.sh)

**ALWAYS run from repository root:**

```bash
# Basic usage (one item per line via stdin)
echo "path/to/file.txt" | ./auto-loop.sh <model> "Fix the issue in"

# With custom copilot flags
git diff --name-only HEAD~1 | ./auto-loop.sh claude-sonnet "Refactor" -- --yolo

# With multiple files
find . -name "*.ts" | ./auto-loop.sh gpt-5 "Add type annotations to"
```

**Valid Models** (as of Jan 2026):

- `claude-sonnet-4.5`, `claude-haiku-4.5`, `claude-opus-4.5`, `claude-sonnet-4`
- `gpt-5.2-codex`, `gpt-5.1-codex-max`, `gpt-5.1-codex`, `gpt-5.2`, `gpt-5.1`,
  `gpt-5`, `gpt-5.1-codex-mini`, `gpt-5-mini`
- `gpt-4.1`, `gemini-3-pro-preview`

**CRITICAL**: Script exits on first copilot failure. No error recovery.

### Parallel Execution (auto-parallel.sh)

**ALWAYS run from repository root:**

```bash
# Install dependencies for examples/ first
cd examples && npm install && cd ..

# Run with parallelism
cat examples/features.txt | ./auto-parallel.sh claude-sonnet-4.5 "Implement" --parallel 4 -- --agent task

# Review changes in each worktree
for w in .worktrees/worker-*; do git -C "$w" status; done

# Merge changes back to main (MANUAL STEP - review first!)
for w in .worktrees/worker-*; do git -C "$w" push origin HEAD; done
git pull

# Clean up worktrees after merging
git worktree remove .worktrees/worker-*
rm -rf .worktrees/
```

**CRITICAL Worktree Behaviors**:

- Worktrees persist in `.worktrees/worker-<N>/` and are **reused** across runs
- Each worker gets an isolated git worktree at HEAD
- `.worktrees/.locks/` directory used internally (auto-cleaned on exit)
- ALWAYS review changes before merging (`git -C "$w" diff`)
- Clean up manually after work completes

### Running Tests

**Full integration test (requires copilot API access):**

```bash
# ALWAYS run from repository root
./tests.sh
```

**What tests.sh does**:

1. Creates temporary directory with git repo
2. Copies `examples/` to temp location
3. Runs `npm install --silent` in examples/
4. Executes `auto-parallel.sh` with 180-second timeout
5. Displays diff stats and commit logs for each worktree
6. Cleans up on exit (trap handler)

**Expected behavior**:

- Success: Prints "Test completed successfully!" + temp directory path
- Failure: Script exits with non-zero code (due to `set -e`)
- Timeout: Process killed after 180 seconds

**Time requirements**: Tests typically complete in 90-180 seconds depending on
copilot API response times.

### Working with Examples

```bash
# Install dependencies (ALWAYS do this first)
cd examples
npm install --silent

# Run the Express server
npm start
# Expected: "Server running on port 3000"

# Test the server (in another terminal)
curl http://localhost:3000/
# Expected: {"message":"Hello World"}

# Clean and reinstall
rm -rf node_modules
npm install --silent
```

**CRITICAL**: The examples/ directory is for testing only. Changes made by
auto-parallel.sh will be in `.worktrees/worker-*/examples/`, not the main
examples/ directory.

## Common Errors and Workarounds

### Error: "Invalid model argument"

**Cause**: Using deprecated or non-existent model name (e.g., `gpt-4o-mini`)\
**Fix**: Use one of the valid models listed above (check with `copilot --help`)

### Error: "copilot: command not found"

**Cause**: GitHub Copilot CLI not installed or not in PATH\
**Fix**: Install via `npm install -g @githubnext/copilot-cli` and authenticate

### Error: Git worktree add fails

**Cause**: `.worktrees/worker-N` already exists but is not a valid worktree\
**Fix**: Clean up manually:

```bash
git worktree remove .worktrees/worker-* --force 2>/dev/null || true
rm -rf .worktrees/
```

### Error: tests.sh times out

**Cause**: Copilot API responses slower than 180 seconds\
**Fix**: This is expected behavior. Review partial results in temp directory
(path printed at start).

### Error: "npm install" fails in examples/

**Cause**: Network issues or corrupted package-lock.json\
**Fix**:

```bash
cd examples
rm -rf node_modules package-lock.json
npm install
cd ..
```

### Error: Port 3000 already in use

**Cause**: Previous Express server still running\
**Fix**: `pkill -f "node index.js"` or use different port

## Modification Guidelines

### Script Permissions

All `.sh` files are executable (`chmod +x`). When creating new scripts:

```bash
chmod +x new-script.sh
```

### Editing Shell Scripts

**CRITICAL**: ALWAYS run these commands after ANY shell script modification:

1. **shellcheck** (linting - catches errors and potential issues):

   ```bash
   shellcheck auto-loop.sh auto-parallel.sh tests.sh
   ```

   - Must pass with ZERO warnings or errors
   - Fix all issues before proceeding

2. **shfmt** (formatting - maintains consistent style):
   ```bash
   shfmt -w -i 0 auto-loop.sh auto-parallel.sh tests.sh
   ```

   - `-w`: Write result to file
   - `-i 0`: Use tabs for indentation
   - ALWAYS run after editing

**Additional guidelines**:

- **Error handling**: auto-loop.sh uses `|| exit 1`, auto-parallel.sh uses
  `|| :`
- **Always test** changes by running the script with a simple input

### Adding New Features

When modifying scripts:

1. **Test with simple input first**:

   ```bash
   echo "test.txt" | ./auto-loop.sh gpt-5-mini "List the filename"
   ```

2. **Validate exit codes**:

   ```bash
   echo "test.txt" | ./auto-loop.sh <model> <prompt>
   echo "Exit code: $?"
   ```

3. **Clean up worktrees** after testing auto-parallel.sh:

   ```bash
   git worktree remove .worktrees/worker-* --force 2>/dev/null || true
   rm -rf .worktrees/
   ```

4. **Run shellcheck and shfmt** (if modifying shell scripts):

   ```bash
   shellcheck auto-loop.sh auto-parallel.sh tests.sh
   shfmt -w -i 0 auto-loop.sh auto-parallel.sh tests.sh
   ```

5. **Verify examples/ still works** (if relevant):
   ```bash
   cd examples && npm install && npm start
   ```

### Code Style

- **Philosophy**: Keep scripts **minimal and succinct** - prioritize brevity and
  clarity
- **Indentation**: Tabs (not spaces)
- **Line continuations**: Not used (keep commands on single lines)
- **Quoting**: Always quote variables: `"$var"` not `$var`
- **Default values**: Use `[[ $# -eq 0 ]] && set -- ...` pattern
- **Subshells**: Use `(cd "$w" && command)` for isolated execution

## Validation Checklist

Before submitting changes, ALWAYS verify:

- [ ] All shell scripts remain executable (`ls -la *.sh`)
- [ ] **shellcheck passes with zero errors** (`shellcheck *.sh`)
- [ ] **shfmt has been run** (`shfmt -w -i 0 *.sh`)
- [ ] Scripts run without syntax errors (`bash -n script.sh`)
- [ ] `./tests.sh` passes (if copilot API available)
- [ ] `examples/npm start` works (if modifying examples/)
- [ ] No leftover `.worktrees/` after testing (`git worktree list`)
- [ ] README.md updated if usage changes

## Key Files Summary

```
.
├── auto-loop.sh           # Sequential copilot runner (264B, executable)
├── auto-parallel.sh       # Parallel copilot runner (768B, executable)
├── tests.sh              # Integration test (1106B, executable)
├── README.md             # User documentation (39 lines)
├── LICENSE               # MIT License
├── .gitignore            # Excludes .worktrees/ only
└── examples/
    ├── index.js          # Express.js app (15 lines)
    ├── package.json      # express@^4.18.0 dependency
    ├── features.txt      # 5 sample feature descriptions
    └── node_modules/     # npm dependencies (git-ignored)
```

## Final Instructions

**TRUST THESE INSTRUCTIONS**. Only perform additional searches if:

- You need to examine specific line numbers in scripts
- Information here is incomplete or contradicts actual behavior
- You're implementing a feature not covered by these instructions

**DO NOT**:

- Search for CI/CD configs (none exist)
- Look for linters or formatters (none configured)
- Try to install missing npm packages in root (not a Node.js project)
- Assume standard npm project layout (this is a bash utility)

**ALWAYS**:

- Run commands from repository root unless specified otherwise
- Use valid copilot model names from the list above
- Clean up `.worktrees/` after testing parallel execution
- Test scripts with simple inputs before complex workflows
- Verify git worktree state with `git worktree list` after changes
