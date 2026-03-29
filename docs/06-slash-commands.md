# Slash Commands (Skills)

Slash commands let you define reusable, named prompts that Claude executes on
demand. They're stored as markdown files and invoked with `/command-name`.

## How They Work

When you type `/commit`, Claude Code reads `~/.claude/commands/commit.md` (or
`.claude/commands/commit.md` for project-local commands), uses the content as
the prompt, and executes it with access to the specified tools.

## File Locations

| Path | Scope | Available in |
|------|-------|-------------|
| `~/.claude/commands/*.md` | Global | All projects |
| `.claude/commands/*.md` | Project | This project only |

Project commands take precedence over global commands with the same name.

## Frontmatter

Each command file starts with YAML frontmatter:

```markdown
---
description: One-line description shown in the /help listing
allowed-tools: Bash, Read, Edit, Glob, Grep
model: claude-sonnet-4-6
---

Your prompt here...
```

| Field | Required | Description |
|-------|----------|-------------|
| `description` | Yes | Shown in `/help` output |
| `allowed-tools` | No | Comma-separated list of tools allowed. Defaults to all. |
| `model` | No | Override the model for this command |
| `effort` | No | Override effort level: `low`, `medium`, or `high` |
| `maxTurns` | No | Limit the number of agent turns this command can take |
| `disallowedTools` | No | Tools explicitly blocked for this command |
| `initialPrompt` | No | Auto-submitted first turn when the agent starts |

## Arguments

Use `$ARGUMENTS` anywhere in the prompt to insert what the user typed after
the command name:

```markdown
---
description: Search for a function across the codebase
allowed-tools: Grep, Read
---

Search the codebase for: $ARGUMENTS

Use Grep to find all occurrences, then read the most relevant files to
understand how it's used.
```

Usage: `/find-function getUserById`

## Built-in Commands

Claude Code includes several built-in slash commands:

| Command | Description |
|---------|-------------|
| `/help` | List all available commands |
| `/clear` | Clear the conversation |
| `/compact` | Compress conversation context |
| `/model` | Switch models |
| `/plan` | Enter plan mode |
| `/mcp` | Manage MCP servers |
| `/status` | Show session status |
| `/effort [low\|medium\|high]` | Set model effort/thinking level for the session |
| `/voice` | Activate voice push-to-talk mode |
| `/loop [interval] [prompt]` | Repeat a prompt on a recurring interval (e.g. `/loop 5m check build`) |
| `/schedule` | Create a cloud scheduled task that runs when machine is off |
| `/branch` | Branch the current conversation (replaces `/fork`) |
| `/btw [question]` | Ask a side question without interrupting the current agent |
| `/copy [N]` | Copy the Nth-latest assistant response to clipboard |
| `/rewind` | Restore to a checkpoint — code only, or code and conversation |
| `/teleport` | Pull a web or cloud session into the local terminal |
| `/desktop` | Hand off the terminal session to the Desktop app |
| `/doctor` | Run environment diagnostics |
| `/plugin` | Manage plugins (install, marketplace, toggle) |
| `/fast` | Toggle fast mode |
| `/keybindings` | Open or edit `~/.claude/keybindings.json` |

## Bootstrapper Commands

This bootstrapper installs four commands:

### `/commit`

Creates a well-formed git commit from staged changes. Reads `git diff --staged`,
drafts a commit message, shows it to you, and commits only after confirmation.

Usage: `/commit`

### `/review-pr`

Reviews a pull request for quality, security, and correctness.

Usage: `/review-pr 123` (PR number) or `/review-pr feature-branch`

### `/security-check`

Scans a path for common security vulnerabilities (secrets, injection, auth issues).

Usage: `/security-check` (current dir) or `/security-check src/api/`

### `/daily-standup`

Generates a standup update from recent git activity and open PRs.

Usage: `/daily-standup`

## Writing Good Commands

**Keep commands focused.** A command should do one specific thing well. If you
find yourself writing "Step 1... Step 2... Step 3... Step 10..." it might be
two commands.

**Use explicit steps.** Number the steps Claude should follow. This makes the
command more predictable and easier to debug when it goes wrong.

**Specify allowed-tools.** Lock down which tools the command can use. A
read-only analysis command shouldn't be able to edit files.

**Use `$ARGUMENTS` for input.** Don't hardcode paths or names — let the user
pass them in.

**Test with edge cases.** What happens when called with no arguments? With an
invalid argument? Handle these gracefully.

## Example: Creating a Custom Command

Create `~/.claude/commands/explain.md`:

```markdown
---
description: Explain a function or file in plain English
allowed-tools: Read, Glob, Grep
---

Explain this in plain English: $ARGUMENTS

1. If it looks like a file path, read the file.
2. If it looks like a function name, search for it with Grep, then read
   the relevant file.
3. Explain:
   - What it does (one sentence)
   - How it works (the key steps)
   - When to use it / what calls it
   - Any non-obvious gotchas

Assume the reader is a developer familiar with the language but new to
this specific code.
```

Usage: `/explain src/auth/middleware.go` or `/explain validateUserToken`
