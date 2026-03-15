#!/usr/bin/env bash
# Example: Block Dangerous rm Commands (PreToolUse)
#
# A more comprehensive safety guard that blocks various classes of dangerous
# rm commands, as a layer of defense below settings.json deny rules.
#
# To use:
#   1. Copy to ~/.claude/hooks/pre-tool-use.sh (or add this logic to it)
#   2. Ensure it's registered in settings.json under PreToolUse
#   3. chmod +x the script
#
# Exit 0 = allow, Exit 2 = block (stdout shown to Claude)

set -uo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

# Only check Bash commands
if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

# Parse the command
CMD=""
if command -v python3 &>/dev/null; then
  CMD="$(python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d.get('command', ''))
except Exception:
    pass
" <<< "$TOOL_INPUT" 2>/dev/null)"
fi

if [[ -z "$CMD" ]]; then
  exit 0
fi

# ── Block patterns ────────────────────────────────────────────────────────────

# rm -rf on root, home, or common top-level paths
if echo "$CMD" | grep -qE 'rm\s+-[a-zA-Z]*rf?[a-zA-Z]*\s+(/|~/|/root|/home|/usr|/etc|/var|/opt)\s*/?$'; then
  echo "BLOCKED: Recursive delete of a system-critical directory."
  echo "Command was: $CMD"
  exit 2
fi

# rm -rf with shell variable expansion that could resolve to dangerous paths
if echo "$CMD" | grep -qE 'rm\s+-[a-zA-Z]*rf?[a-zA-Z]*\s+\$(HOME|USER|PWD|OLDPWD)\s*/?$'; then
  echo "BLOCKED: Recursive delete using a shell variable that may expand to a critical path."
  echo "Command was: $CMD"
  exit 2
fi

# dd writing to a raw disk device
if echo "$CMD" | grep -qE 'dd\s+.*of=/dev/(sd[a-z]|nvme[0-9]n[0-9]|hd[a-z])\b'; then
  echo "BLOCKED: dd writing to a raw disk device."
  echo "Command was: $CMD"
  exit 2
fi

# mkfs formatting a disk (not a file)
if echo "$CMD" | grep -qE 'mkfs\s+.*\s+/dev/(sd[a-z]|nvme[0-9]n[0-9]|hd[a-z])\b'; then
  echo "BLOCKED: mkfs formatting a raw disk device."
  echo "Command was: $CMD"
  exit 2
fi

exit 0
