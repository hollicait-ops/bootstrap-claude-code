#!/usr/bin/env bash
# Example: Desktop Notification on Stop
#
# Sends a desktop notification when Claude finishes responding.
# Useful when running long tasks — step away and get notified when done.
#
# To use:
#   1. Copy to ~/.claude/hooks/stop.sh (or add this logic to it)
#   2. Ensure it's registered in settings.json under Stop
#   3. chmod +x the script
#
# Requirements:
#   macOS: works out of the box (uses osascript)
#   Linux: requires notify-send (install: apt install libnotify-bin)

set -euo pipefail

TITLE="Claude Code"
MESSAGE="Claude has finished."

if [[ "$(uname)" == "Darwin" ]]; then
  # macOS
  osascript -e "display notification \"${MESSAGE}\" with title \"${TITLE}\"" &>/dev/null || true

  # Optionally also play a sound:
  # afplay /System/Library/Sounds/Ping.aiff &>/dev/null || true

elif command -v notify-send &>/dev/null; then
  # Linux (GNOME, KDE, etc.)
  notify-send "$TITLE" "$MESSAGE" --urgency=low &>/dev/null || true

elif command -v terminal-notifier &>/dev/null; then
  # macOS alternative (brew install terminal-notifier)
  terminal-notifier -title "$TITLE" -message "$MESSAGE" &>/dev/null || true
fi

exit 0
