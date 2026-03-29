#!/usr/bin/env bash
# PreToolUse Hook — runs before every tool call
#
# Environment variables available:
#   CLAUDE_TOOL_NAME   — name of the tool about to run (e.g., "Bash", "Edit")
#   CLAUDE_TOOL_INPUT  — JSON-encoded tool input
#
# Exit codes:
#   0 — allow the tool to run
#   2 — block the tool (stdout is shown to Claude as the reason)
#
# This template blocks catastrophically destructive shell commands as a
# last-resort safety net below the deny rules in settings.json.
# All other behaviors are commented out — opt in by uncommenting.

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

# =============================================================================
# ACTIVE — this code runs automatically on every tool call
# =============================================================================

# ── Safety guard: block root/home recursive deletes ─────────────────────────
if [[ "$TOOL_NAME" == "Bash" ]]; then
  # Extract the command from JSON input.
  # Use python3 if available; fall back to grep/sed so the guard stays active
  # even on systems without python3.
  if command -v python3 &>/dev/null; then
    COMMAND="$(TOOL_INPUT="$TOOL_INPUT" python3 -c "
import os, json
try:
    d = json.loads(os.environ['TOOL_INPUT'])
    print(d.get('command', ''))
except Exception:
    pass
" 2>/dev/null)"
  else
    # Shell-only fallback: extract the "command" field value from JSON.
    # Handles standard single-line JSON; good enough for safety pattern matching.
    COMMAND="$(printf '%s' "$TOOL_INPUT" \
      | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' \
      | head -1 \
      | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//; s/"$//')"
  fi

  # Block: rm -rf / or rm -rf ~ (combined flags: -rf, -fr, -Rf, etc.)
  if echo "$COMMAND" | grep -qE 'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f[[:space:]]+(/|~|/root|\$HOME)'; then
    echo "BLOCKED: Attempted to recursively delete a root-level or home directory. This is almost certainly a mistake."
    exit 2
  fi

  # Block: rm -r -f / or rm -f -r ~ (space-separated flags)
  if echo "$COMMAND" | grep -qE '^rm[[:space:]]' && \
     echo "$COMMAND" | grep -qE '[[:space:]](-r|-R|--recursive)([[:space:]]|$)' && \
     echo "$COMMAND" | grep -qE '[[:space:]](-f|--force)([[:space:]]|$)' && \
     echo "$COMMAND" | grep -qE '[[:space:]](/|~|/root|\$HOME)'; then
    echo "BLOCKED: Attempted to recursively delete a root-level or home directory. This is almost certainly a mistake."
    exit 2
  fi

  # Block: dd if=/dev/zero targeting a whole disk
  if echo "$COMMAND" | grep -qE 'dd[[:space:]].*of=/dev/(sd[a-z]|nvme[0-9])'; then
    echo "BLOCKED: Attempted to overwrite a raw disk device with dd."
    exit 2
  fi
fi

# =============================================================================
# OPTIONAL — uncomment any section below to enable it
# =============================================================================

# ── Optional: log every tool call to an audit file ──────────────────────────
# LOG_FILE="${HOME}/.claude/tool-audit.log"
# echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) PRE  TOOL=${TOOL_NAME}" >> "$LOG_FILE"

# ── Optional: require confirmation before any npm publish ───────────────────
# if [[ "$TOOL_NAME" == "Bash" ]]; then
#   if echo "$COMMAND" | grep -q 'npm publish'; then
#     read -r -p "About to run: $COMMAND  — Continue? [y/N] " reply
#     [[ "$reply" =~ ^[Yy]$ ]] || { echo "Cancelled by user."; exit 2; }
#   fi
# fi

exit 0
