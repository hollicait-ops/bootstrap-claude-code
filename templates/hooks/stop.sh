#!/usr/bin/env bash
# Stop Hook — runs when Claude finishes generating a response
#
# Use for: completion notifications, session logging, cleanup.
#
# This hook has NO active code by default — it does nothing until you opt in.
#
# =============================================================================
# OPTIONAL — uncomment any section below to enable it
# =============================================================================

# ── Optional: macOS desktop notification ─────────────────────────────────────
# if [[ "$(uname)" == "Darwin" ]]; then
#   osascript -e 'display notification "Claude has finished." with title "Claude Code"' &>/dev/null || true
# fi

# ── Optional: Linux desktop notification (requires notify-send) ──────────────
# if command -v notify-send &>/dev/null; then
#   notify-send "Claude Code" "Claude has finished." &>/dev/null || true
# fi

# ── Optional: play a sound on macOS ──────────────────────────────────────────
# if [[ "$(uname)" == "Darwin" ]]; then
#   afplay /System/Library/Sounds/Ping.aiff &>/dev/null || true
# fi

# ── Optional: log session end timestamp ──────────────────────────────────────
# LOG_FILE="${HOME}/.claude/session.log"
# echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) STOP" >> "$LOG_FILE"

exit 0
