#!/usr/bin/env bash
# SessionStart Hook — runs when a new Claude Code session begins
#
# Use for: environment checks, welcome messages, context loading, reminders.
# All behaviors below are commented out — opt in by uncommenting.

# ── Optional: print a reminder if the project has a PROJECT.md ───────────────
# if [ -f ".claude/PROJECT.md" ]; then
#   echo "📋 Project context available in .claude/PROJECT.md"
# fi

# ── Optional: warn if there are uncommitted changes ──────────────────────────
# if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
#   CHANGED=$(git status --porcelain | wc -l | tr -d ' ')
#   if [ "$CHANGED" -gt 0 ]; then
#     echo "⚠ You have ${CHANGED} uncommitted change(s) in $(git rev-parse --show-toplevel)"
#   fi
# fi

# ── Optional: print the current branch ───────────────────────────────────────
# if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
#   BRANCH="$(git branch --show-current 2>/dev/null)"
#   [ -n "$BRANCH" ] && echo "🌿 Branch: $BRANCH"
# fi

exit 0
