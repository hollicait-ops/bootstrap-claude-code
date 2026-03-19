#!/usr/bin/env bash
# PostToolUse Hook — runs after every tool call
#
# Environment variables available:
#   CLAUDE_TOOL_NAME    — name of the tool that ran
#   CLAUDE_TOOL_INPUT   — JSON-encoded tool input
#   CLAUDE_TOOL_RESULT  — JSON-encoded tool result
#
# Exit code is ignored by Claude Code for PostToolUse hooks.
#
# All behaviors below are commented out — opt in by uncommenting.

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
# TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
# TOOL_RESULT="${CLAUDE_TOOL_RESULT:-}"

# ── Optional: append every tool call to an audit log ────────────────────────
# LOG_FILE="${HOME}/.claude/tool-audit.log"
# echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) POST TOOL=${TOOL_NAME}" >> "$LOG_FILE"

# ── Optional: run tests automatically after any file edit ───────────────────
# if [[ "$TOOL_NAME" == "Edit" || "$TOOL_NAME" == "Write" ]]; then
#   if [ -f "package.json" ]; then
#     npm test --silent 2>/dev/null || true
#   fi
# fi

# ── Optional: auto-format after edits (e.g., prettier) ──────────────────────
# if [[ "$TOOL_NAME" == "Edit" ]] && command -v prettier &>/dev/null; then
#   FILE="$(python3 -c "import sys,json; d=json.loads('${CLAUDE_TOOL_INPUT}'); print(d.get('file_path',''))" 2>/dev/null)"
#   [ -n "$FILE" ] && prettier --write "$FILE" &>/dev/null || true
# fi

exit 0
