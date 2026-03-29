# Hooks

Hooks are shell scripts that Claude Code executes automatically in response to
events — before/after tool calls, at session start/end, and more. They're used
for safety guards, audit logging, notifications, and automation.

## Hook Events

| Event | When it fires | Can block? |
|-------|--------------|------------|
| `PreToolUse` | Before each tool call | Yes (exit 2) |
| `PostToolUse` | After each tool call | No |
| `Stop` | When Claude finishes a response | No |
| `SessionStart` | When a session begins | No |
| `SessionEnd` | When a session ends | No |
| `PostCompact` | After context compaction | No |
| `StopFailure` | On API errors (rate limits, auth failures) | No |
| `CwdChanged` | When the working directory changes | No |
| `FileChanged` | When a watched file changes on disk | No |
| `TaskCreated` | When a task is created via the TaskCreate tool | No |
| `WorktreeCreate` | Before a git worktree is created (can override behavior) | No |
| `WorktreeRemove` | When a git worktree is removed | No |
| `SubagentStart` | When a subagent process starts | No |
| `SubagentStop` | When a subagent process stops | No |

## Exit Codes

For `PreToolUse` hooks only:

| Exit code | Meaning |
|-----------|---------|
| `0` | Allow the tool call to proceed |
| `2` | Block the tool call; stdout is sent to Claude as the reason |
| Other | Treated as an error; tool call may proceed with a warning |

## Environment Variables

Available in all hook scripts:

| Variable | Description |
|----------|-------------|
| `CLAUDE_TOOL_NAME` | Name of the tool (e.g., `Bash`, `Edit`, `Read`) |
| `CLAUDE_TOOL_INPUT` | JSON-encoded tool input |
| `CLAUDE_TOOL_RESULT` | JSON-encoded tool result (PostToolUse only) |

## Registering Hooks

Hooks are registered in `settings.json`. The installer does this automatically,
but here's the manual format:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [{"type": "command", "command": "/home/user/.claude/hooks/pre-tool-use.sh"}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "/home/user/.claude/hooks/post-tool-use.sh"}]
      }
    ],
    "Stop": [
      {
        "hooks": [{"type": "command", "command": "/home/user/.claude/hooks/stop.sh"}]
      }
    ],
    "SessionStart": [
      {
        "hooks": [{"type": "command", "command": "/home/user/.claude/hooks/session-start.sh"}]
      }
    ]
  }
}
```

The `matcher` field (for PreToolUse/PostToolUse) is a tool name or `"*"` for all.

### Hook Options

**`async: true`** — Run the hook in the background without blocking Claude:

```json
{
  "type": "command",
  "command": "/path/to/hook.sh",
  "async": true
}
```

Use this for notifications or logging where you don't need the result before
Claude continues.

**`if` field** — Conditionally fire the hook using the same permission rule
syntax as `settings.json` allow/deny rules (see [01-settings.md](01-settings.md)):

```json
{
  "matcher": "Bash",
  "if": "Bash(git *)",
  "hooks": [{"type": "command", "command": "/path/to/hook.sh"}]
}
```

The hook only runs when the tool call matches the `if` pattern. Useful for
narrowing a broad `"*"` matcher to specific commands without needing separate
hook entries.

### Hook Types

| Type | When to use | Availability |
|------|-------------|--------------|
| `command` | Run a shell script or CLI command | All events |
| `prompt` | Ask an LLM to evaluate a condition (e.g. "is this safe?") | PreToolUse, PostToolUse only |
| `agent` | Spawn a full subagent for complex multi-step validation | PreToolUse, PostToolUse only |
| `http` | POST the hook payload to a URL (webhooks, external services) | All events |

## Hook Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

# Parse the command from a Bash tool input
get_command() {
  python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d.get('command', ''))
except Exception:
    pass
" <<< "$TOOL_INPUT"
}

if [[ "$TOOL_NAME" == "Bash" ]]; then
  CMD="$(get_command)"
  # ... your logic here ...
fi

exit 0
```

## Practical Examples

### Safety Guard (PreToolUse)

Block any command that looks like a recursive root delete:

```bash
#!/usr/bin/env bash
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

if [[ "$TOOL_NAME" == "Bash" ]]; then
  CMD=$(python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('command',''))" <<< "$TOOL_INPUT" 2>/dev/null)
  if echo "$CMD" | grep -qE 'rm\s+-[a-zA-Z]*rf?\s+(/|~)\s*$'; then
    echo "BLOCKED: Recursive delete of root or home directory."
    exit 2
  fi
fi

exit 0
```

### Audit Logger (PostToolUse)

Log every tool call to a file for compliance or debugging:

```bash
#!/usr/bin/env bash
LOG_FILE="${HOME}/.claude/tool-audit.log"
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) TOOL=${CLAUDE_TOOL_NAME:-unknown}" >> "$LOG_FILE"
exit 0
```

### Completion Notification (Stop)

Send a desktop notification when Claude finishes:

```bash
#!/usr/bin/env bash
if [[ "$(uname)" == "Darwin" ]]; then
  osascript -e 'display notification "Claude has finished." with title "Claude Code"' &>/dev/null || true
elif command -v notify-send &>/dev/null; then
  notify-send "Claude Code" "Claude has finished." &>/dev/null || true
fi
exit 0
```

### Auto-format on Edit (PostToolUse)

Run prettier after any file edit:

```bash
#!/usr/bin/env bash
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

if [[ "$TOOL_NAME" == "Edit" || "$TOOL_NAME" == "Write" ]] && command -v prettier &>/dev/null; then
  FILE=$(python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('file_path',''))" <<< "$TOOL_INPUT" 2>/dev/null)
  [ -n "$FILE" ] && prettier --write "$FILE" &>/dev/null || true
fi
exit 0
```

## Timeouts

Hooks have a default timeout. If a hook exceeds it, Claude Code logs a warning
and continues. For `SessionEnd` hooks specifically, the timeout can be controlled
with the `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` environment variable.

## Debugging Hooks

Run Claude Code with verbose output to see hook execution:

```bash
claude --verbose
```

You can also test a hook directly:

```bash
CLAUDE_TOOL_NAME="Bash" CLAUDE_TOOL_INPUT='{"command":"rm -rf /"}' \
  ~/.claude/hooks/pre-tool-use.sh
echo "Exit code: $?"
```

## Important Notes

- Hooks run as the current user with full shell access — do not store untrusted
  input in ways that could lead to injection.
- The installed hook templates exit 0 and do nothing by default. All behaviors
  are opt-in via uncommenting.
- Use absolute paths for hook scripts in `settings.json` — relative paths may
  not resolve correctly when Claude Code runs from different directories.
