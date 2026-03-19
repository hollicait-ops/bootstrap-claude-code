#!/usr/bin/env bash
# Example: Audit Logger (PostToolUse)
#
# Logs every tool call to ~/.claude/tool-audit.log with timestamp, tool name,
# and (for Bash tools) the command that was run.
#
# To use:
#   1. Copy to ~/.claude/hooks/post-tool-use.sh (or add this logic to it)
#   2. Ensure it's registered in settings.json under PostToolUse
#   3. chmod +x the script

set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
LOG_FILE="${HOME}/.claude/tool-audit.log"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# For Bash tools, also log the command
EXTRA=""
if [[ "$TOOL_NAME" == "Bash" ]] && command -v python3 &>/dev/null; then
  CMD="$(python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d.get('command', '').split('\n')[0][:120])
except Exception:
    pass
" <<< "$TOOL_INPUT" 2>/dev/null)"
  [ -n "$CMD" ] && EXTRA=" CMD=${CMD}"
fi

# For Edit/Write tools, log the file path
if [[ "$TOOL_NAME" == "Edit" || "$TOOL_NAME" == "Write" ]] && command -v python3 &>/dev/null; then
  FILEPATH="$(python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d.get('file_path', ''))
except Exception:
    pass
" <<< "$TOOL_INPUT" 2>/dev/null)"
  [ -n "$FILEPATH" ] && EXTRA=" FILE=${FILEPATH}"
fi

echo "${TIMESTAMP} TOOL=${TOOL_NAME}${EXTRA}" >> "$LOG_FILE"

exit 0
