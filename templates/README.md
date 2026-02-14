# Workflow Templates

These templates support the **Feature Development Workflow** pattern for
`auto-loop`.

## Quick Start

1. **Copy templates to your project root:**
   ```bash
   cp templates/.todos.md .
   cp templates/.prompt.md .
   cp templates/.after-group.md .
   ```

2. **Edit each file:**
   - `.todos.md`: Add your user stories with group headers
   - `.prompt.md`: Define your project context
   - `.after-group.md`: Customize the review command

3. **Run the workflow:**
   ```bash
   cat .todos.md | ./auto-loop.rb \
     --model gpt-5-mini \
     --prompt "$(cat .prompt.md)" \
     --group-pattern '^\*\*.*:\*\*' \
     --after-group "$(cat .after-group.md)"
   ```

## Or Use the Feature Scaffolder Agent

Instead of manually editing templates, use the custom Copilot agent:

1. In VS Code with Copilot, open chat
2. Say: **"scaffold this feature spec"** or **"break this down for auto-loop"**
3. Provide your functional specification
4. The agent will generate all three files for you

See
[../.github/agents/feature-scaffolder.md](../.github/agents/feature-scaffolder.md)
for more details.
