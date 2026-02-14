# Copilot Agent Instructions for auto-loop

## Repository Overview

This repository provides a **Ruby script** for running GitHub Copilot CLI
commands in batch mode across multiple targets. It's a small utility (< 60 lines
of Ruby) designed to automate copilot tasks over lists of files, features, or
other inputs.

**Design Philosophy**: Code must be **minimal and succinct**. Keep code terse,
avoid unnecessary complexity, and prioritize readability through brevity.

**Type**: Ruby utility script\
**Size**: Minimal (1 Ruby script + 1 shell test + 1 example Node.js app)\
**Languages**: Ruby (primary), Bash (tests only), JavaScript (examples only)\
**Target Runtime**: Ruby 3.x+, GitHub Copilot CLI 0.0.392+\
**Purpose**: Automate copilot CLI invocations with grouping and validation
support

## Core Architecture

### Main Scripts (Root Directory)

1. **`auto-loop.rb`**
   - Sequential processor: pipes stdin lines → copilot CLI invocations
   - Usage:
     `<command> | ./auto-loop.rb --model <model> --prompt <prompt> [options] [-- <copilot-flags>]`
   - Options: `--validate`, `--group-pattern`, `--after-group`
   - Exits on first failure unless `--validate` is set (retries indefinitely)
   - Defaults: `--allow-all-tools --disallow-temp-dir --silent`

2. **`tests.sh`**
   - Integration test: sets up temp environment, runs auto-loop.rb
   - Timeout: 180 seconds
   - Requires npm for examples/ dependencies

### Examples Directory

- **`examples/index.js`**: Basic Express.js server (15 lines, port 3000)
- **`examples/package.json`**: Dependencies: `express@^4.18.0`
- **`examples/features.txt`**: 5-line feature list for testing
- **Purpose**: Demonstrates auto-loop.rb by implementing Express endpoints

### Configuration

- **`.gitignore`**: Excludes `.worktrees/` directory only
- **Shell linting**: shellcheck 0.11.0+ required for shell script changes
- **Shell formatting**: shfmt 3.12.0+ required for shell script changes
- **No CI/CD configured**

## Environment Requirements

### ALWAYS Install These First

1. **Ruby 3.x+**
   - Verify: `ruby --version`
   - macOS: Pre-installed or `brew install ruby`

2. **GitHub Copilot CLI 0.0.392+**
   - Verify: `copilot --version`
   - Must be authenticated and configured

3. **Git 2.50+**
   - Verify: `git --version`

4. **Bash 5.3.9+** (for tests.sh only)
   - Verify: `bash --version`
   - macOS: Install via `brew install bash`

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

### Sequential Execution (auto-loop.rb)

**ALWAYS run from repository root:**

```bash
# Basic usage (one item per line via stdin)
echo "path/to/file.txt" | ./auto-loop.rb --model <model> --prompt "Fix the issue in"

# With validation (retries until passing)
echo "test.js" | ./auto-loop.rb --model claude-sonnet --prompt "Write passing tests" --validate "npm test"

# With custom copilot flags
git diff --name-only HEAD~1 | ./auto-loop.rb --model claude-sonnet --prompt "Refactor" -- --yolo

# With grouped processing
cat tasks.md | ./auto-loop.rb --model gpt-5 --prompt "Implement" --group-pattern '^\*\*.*:\*\*' --after-group "npm test"
```

**Valid Models** (as of Jan 2026):

- `claude-sonnet-4.5`, `claude-haiku-4.5`, `claude-opus-4.5`, `claude-sonnet-4`
- `gpt-5.2-codex`, `gpt-5.1-codex-max`, `gpt-5.1-codex`, `gpt-5.2`, `gpt-5.1`,
  `gpt-5`, `gpt-5.1-codex-mini`, `gpt-5-mini`
- `gpt-4.1`, `gemini-3-pro-preview`

**CRITICAL**: Script exits on first copilot failure unless `--validate` is set.

### Running Tests

**Full integration test (requires copilot API access):**

```bash
# ALWAYS run from repository root
./tests.sh
```

**What tests.sh does**:

1. Creates temporary directory with git repo
2. Copies `examples/` and `auto-loop.rb` to temp location
3. Runs `npm install --silent` in examples/
4. Executes `auto-loop.rb` with 180-second timeout
5. Displays diff stats and commit logs
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

**CRITICAL**: The examples/ directory is for testing only.

## Common Errors and Workarounds

### Error: "Invalid model argument"

**Cause**: Using deprecated or non-existent model name (e.g., `gpt-4o-mini`)\
**Fix**: Use one of the valid models listed above (check with `copilot --help`)

### Error: "copilot: command not found"

**Cause**: GitHub Copilot CLI not installed or not in PATH\
**Fix**: Install via `npm install -g @githubnext/copilot-cli` and authenticate

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
   shellcheck tests.sh
   ```

   - Must pass with ZERO warnings or errors
   - Fix all issues before proceeding

2. **shfmt** (formatting - maintains consistent style):

   ```bash
   shfmt -w -i 0 tests.sh
   ```

   - `-w`: Write result to file
   - `-i 0`: Use tabs for indentation
   - ALWAYS run after editing

**Additional guidelines**:

- **Always test** changes by running the script with a simple input

### Adding New Features

When modifying scripts:

1. **Test with simple input first**:

   ```bash
   echo "test.txt" | ./auto-loop.rb --model gpt-5-mini --prompt "List the filename"
   ```

2. **Validate exit codes**:

   ```bash
   echo "test.txt" | ./auto-loop.rb --model <model> --prompt <prompt>
   echo "Exit code: $?"
   ```

3. **Run shellcheck and shfmt** (if modifying shell scripts):

   ```bash
   shellcheck tests.sh
   shfmt -w -i 0 tests.sh
   ```

4. **Verify examples/ still works** (if relevant):
   ```bash
   cd examples && npm install && npm start
   ```

### Code Style

- **Philosophy**: Keep code **minimal and succinct** - prioritize brevity and
  clarity
- **Ruby**: Use idiomatic Ruby, prefer standard library over gems
- **Shell (tests.sh)**: Tabs for indentation, quote variables

## Validation Checklist

Before submitting changes, ALWAYS verify:

- [ ] `ruby -c auto-loop.rb` passes (syntax check)
- [ ] Shell scripts remain executable (`ls -la *.sh`)
- [ ] **shellcheck passes with zero errors** (`shellcheck tests.sh`)
- [ ] **shfmt has been run** (`shfmt -w -i 0 tests.sh`)
- [ ] `./tests.sh` passes (if copilot API available)
- [ ] `examples/npm start` works (if modifying examples/)
- [ ] README.md updated if usage changes

## Key Files Summary

```
.
├── auto-loop.rb           # Sequential copilot runner (Ruby, executable)
├── tests.sh              # Integration test (executable)
├── README.md             # User documentation
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
- Assume standard npm project layout (this is a Ruby utility)

**ALWAYS**:

- Run commands from repository root unless specified otherwise
- Use valid copilot model names from the list above
- Test scripts with simple inputs before complex workflows
