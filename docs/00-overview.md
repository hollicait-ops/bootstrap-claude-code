# Overview: Claude Code Bootstrapper

## What is Claude Code?

Claude Code is Anthropic's official CLI for Claude — an AI coding assistant that
runs directly in your terminal. Unlike chat-based AI tools, Claude Code:

- Has direct access to your filesystem, shell, and git repository
- Can read, write, and edit files without copy-pasting
- Runs shell commands, tests, and builds on your behalf
- Maintains persistent memory across sessions
- Is extensible via hooks, MCP servers, and custom slash commands

## What This Bootstrapper Sets Up

Running `./install.sh` configures the following at `~/.claude/`:

| File / Directory | What it does |
|-----------------|--------------|
| `settings.json` | Permissions (allow/deny/ask rules), model, hooks registration |
| `CLAUDE.md` | Global instructions loaded in every session |
| `keybindings.json` | Keyboard shortcuts |
| `memory/MEMORY.md` | Persistent memory index |
| `hooks/*.sh` | Shell scripts triggered on tool events |
| `commands/*.md` | Custom slash commands (`/commit`, `/review-pr`, etc.) |

All changes are reversible: the installer backs up your existing configs before
making any changes, and `uninstall.sh` restores them.

## Prerequisites

1. **Claude Code** — Install with:
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```
   Or download from https://claude.ai/download

2. **An Anthropic account** — Sign up at https://console.anthropic.com

3. **Bash 4+** — Required by `install.sh`. On macOS the default bash is 3.x;
   upgrade with `brew install bash`.

4. **python3** (recommended) — Used for smart JSON merging. Available on most
   systems; install via your package manager if needed.

## Quick Start

```bash
# Clone or download the bootstrapper
git clone https://github.com/your-org/bootstrap-claude-code
cd bootstrap-claude-code

# Run the installer (will prompt before making any changes)
./install.sh

# Or preview without making changes
./install.sh --dry-run

# Start Claude Code
claude
```

## What Happens After Install

1. Claude Code will use `claude-sonnet-4-6` by default (configurable in `settings.json`)
2. Dangerous commands like `rm -rf /` are blocked by deny rules
3. Network-write operations like `git push` require your confirmation
4. Four custom slash commands are ready: `/commit`, `/review-pr`, `/security-check`, `/daily-standup`
5. Hook scripts are installed but do nothing by default — opt in by editing them

## Examples

The `examples/` directory has ready-to-use configurations:

- [examples/settings/settings-full.json](../examples/settings/settings-full.json) — Fully annotated settings for macOS/Linux
- [examples/settings/settings-full-windows.json](../examples/settings/settings-full-windows.json) — Fully annotated settings for Windows (PowerShell hook paths, Windows-specific entries)
- [examples/hooks/](../examples/hooks/) — Audit logger, desktop notifications, safety guards
- [examples/mcp/](../examples/mcp/) — Filesystem, GitHub, and web search MCP configs
- [examples/claude-md/](../examples/claude-md/) — CLAUDE.md templates for Python, Next.js, and personal use

## Customization

Every file installed by this bootstrapper is meant to be edited. Start with:

- **`~/.claude/CLAUDE.md`** — Add your preferred working style, project conventions
- **`~/.claude/settings.json`** — Tune the allow/deny rules for your workflow
- **`~/.claude/hooks/*.sh`** — Uncomment behaviors you want (notifications, auto-format, etc.)

## User Guide

The `docs/` directory contains a complete reference for every Claude Code feature:

| Guide | Topic |
|-------|-------|
| [01-settings.md](01-settings.md) | settings.json permissions, model, all options |
| [02-claude-md.md](02-claude-md.md) | Writing effective CLAUDE.md instruction files |
| [03-memory.md](03-memory.md) | Persistent memory system |
| [04-hooks.md](04-hooks.md) | Shell hooks for automation and safety |
| [05-mcp-servers.md](05-mcp-servers.md) | Extending Claude with MCP tools |
| [06-slash-commands.md](06-slash-commands.md) | Custom slash commands / skills |
| [07-keybindings.md](07-keybindings.md) | Keyboard shortcuts |
| [08-plan-mode.md](08-plan-mode.md) | Structured planning before execution |
| [09-subagents.md](09-subagents.md) | Parallel and specialized subagents |
| [10-advanced-patterns.md](10-advanced-patterns.md) | Combining features for powerful workflows |
| [11-troubleshooting.md](11-troubleshooting.md) | Common problems and how to fix them |
| [12-plugins.md](12-plugins.md) | Installing and managing plugins |
| [13-voice-mode.md](13-voice-mode.md) | Voice input with push-to-talk |
| [14-scheduled-tasks.md](14-scheduled-tasks.md) | Recurring tasks with /loop and /schedule |
