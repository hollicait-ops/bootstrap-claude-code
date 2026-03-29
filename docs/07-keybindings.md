# Keybindings

Customize keyboard shortcuts for Claude Code actions.

## Configuration File

`~/.claude/keybindings.json`

```json
[
  {
    "key": "ctrl+shift+p",
    "command": "claude.openPlanMode",
    "description": "Enter plan mode"
  }
]
```

Each entry requires `key` and `command`. `description` is optional but helpful.

## Key Syntax

Modifiers: `ctrl`, `shift`, `alt`, `meta` (Cmd on macOS)

Combine with `+`: `ctrl+shift+p`, `alt+enter`, `meta+k`

Single keys: `space`, `escape`, `enter`, `tab`, `f1`–`f12`

## Available Commands

| Command | Default | Description |
|---------|---------|-------------|
| `claude.openPlanMode` | — | Enter plan mode |
| `claude.openMemory` | — | Open memory viewer |
| `claude.clearConversation` | — | Clear current conversation |
| `voice:pushToTalk` | `space` | Hold to speak (voice input) |

## Bootstrapper Defaults

The bootstrapper installs these bindings (only if the key slot is unused):

```json
[
  {"key": "ctrl+shift+p", "command": "claude.openPlanMode"},
  {"key": "ctrl+shift+m", "command": "claude.openMemory"},
  {"key": "ctrl+shift+.", "command": "claude.clearConversation"},
  {"key": "space",        "command": "voice:pushToTalk"}
]
```

## Changing the Voice Push-to-Talk Key

The voice push-to-talk key defaults to `space`. To change it:

```json
[
  {"key": "ctrl+space", "command": "voice:pushToTalk"}
]
```

## Removing a Binding

To remove a binding installed by the bootstrapper, delete its entry from
`~/.claude/keybindings.json`.

## Notes

- Changes take effect at the next Claude Code session start.
- There is no binding conflict detection — if two entries share a key, the
  last one in the array wins.

---

## User Guide

| Guide | Topic |
|-------|-------|
| [00-overview.md](00-overview.md) | Overview and quick start |
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
