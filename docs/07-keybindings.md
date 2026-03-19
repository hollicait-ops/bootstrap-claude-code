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
