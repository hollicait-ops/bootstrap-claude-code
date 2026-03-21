#!/usr/bin/env bash
# uninstall.sh — Claude Code Bootstrapper Removal
#
# Removes all files installed by install.sh and optionally restores a backup.
# Usage: ./uninstall.sh [--restore-backup <path>] [--dry-run]

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
VERSION_FILE="${CLAUDE_DIR}/.bootstrapper-version"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

log()     { echo -e "${BLUE}[info]${RESET}  $*"; }
ok()      { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
error()   { echo -e "${RED}[error]${RESET} $*" >&2; }
heading() { echo -e "\n${BOLD}$*${RESET}"; }

DRY_RUN=false
RESTORE_BACKUP=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)           DRY_RUN=true ;;
    --restore-backup)    RESTORE_BACKUP="${2:-}" ; shift ;;
    --restore-backup=*)  RESTORE_BACKUP="${1#*=}" ;;
    --help|-h)
      echo "Usage: $0 [--restore-backup <backup-dir>] [--dry-run]"
      echo ""
      echo "  --restore-backup <path>  Restore a specific backup directory"
      echo "  --dry-run                Show what would be removed without doing it"
      exit 0
      ;;
    *) ;;
  esac
  shift
done

dry() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[dry-run]${RESET} Would run: $*"
    return 0
  fi
  "$@"
}

echo -e "${BOLD}Claude Code Bootstrapper — Uninstall${RESET}"
echo "────────────────────────────────────────"

if [[ "$DRY_RUN" == "true" ]]; then
  echo -e "${YELLOW}DRY RUN MODE — no changes will be made${RESET}\n"
fi

# Check if bootstrapper is installed
if [[ ! -f "$VERSION_FILE" ]]; then
  warn "No bootstrapper installation found (missing $VERSION_FILE)."
  warn "Files may still exist and will be listed below."
fi

# Files installed by the bootstrapper
INSTALLED_FILES=(
  "${CLAUDE_DIR}/settings.json"
  "${CLAUDE_DIR}/CLAUDE.md"
  "${CLAUDE_DIR}/keybindings.json"
  "${CLAUDE_DIR}/memory/MEMORY.md"
  "${CLAUDE_DIR}/hooks/pre-tool-use.sh"
  "${CLAUDE_DIR}/hooks/post-tool-use.sh"
  "${CLAUDE_DIR}/hooks/session-start.sh"
  "${CLAUDE_DIR}/hooks/stop.sh"
  "${CLAUDE_DIR}/commands/commit.md"
  "${CLAUDE_DIR}/commands/review-pr.md"
  "${CLAUDE_DIR}/commands/security-check.md"
  "${CLAUDE_DIR}/commands/daily-standup.md"
  "${CLAUDE_DIR}/commands/fix-bug.md"
  "${CLAUDE_DIR}/.bootstrapper-version"
)

# ── Option A: Restore from backup ─────────────────────────────────────────────

if [[ -n "$RESTORE_BACKUP" ]]; then
  heading "Restoring from backup: $RESTORE_BACKUP"

  if [[ ! -d "$RESTORE_BACKUP" ]]; then
    error "Backup directory not found: $RESTORE_BACKUP"
    exit 1
  fi

  # Remove current bootstrapper files first
  for f in "${INSTALLED_FILES[@]}"; do
    if [[ -f "$f" ]]; then
      dry rm "$f"
      ok "Removed: $f"
    fi
  done

  # Restore backed-up files
  for backed_up in "${RESTORE_BACKUP}"/*; do
    name="$(basename "$backed_up")"
    if [[ -f "$backed_up" ]]; then
      dst="${CLAUDE_DIR}/${name}"
      if [[ -f "$dst" ]]; then
        # Skip files modified after the backup was taken
        backup_mtime="$(stat -c %Y "$backed_up" 2>/dev/null || stat -f %m "$backed_up" 2>/dev/null || echo 0)"
        current_mtime="$(stat -c %Y "$dst" 2>/dev/null || stat -f %m "$dst" 2>/dev/null || echo 0)"
        if [[ "$current_mtime" -gt "$backup_mtime" ]]; then
          warn "Skipping ~/.claude/${name} — modified after backup was taken (remove manually to restore)"
          continue
        fi
      fi
      dry cp "$backed_up" "$dst"
      ok "Restored: ~/.claude/${name}"
    elif [[ -d "$backed_up" ]]; then
      dry cp -r "$backed_up" "${CLAUDE_DIR}/${name}"
      ok "Restored: ~/.claude/${name}/"
    fi
  done

  # Restore executable bits on hooks
  if [[ -d "${CLAUDE_DIR}/hooks" && "$DRY_RUN" != "true" ]]; then
    find "${CLAUDE_DIR}/hooks" -name "*.sh" -exec chmod +x {} \;
  fi

  ok "Restore complete."
  exit 0
fi

# ── Option B: Remove bootstrapper files ───────────────────────────────────────

heading "Removing bootstrapper files"

# List available backups
shopt -s nullglob
BACKUPS=("${CLAUDE_DIR}"/bootstrapper-backup-*)
shopt -u nullglob
if (( ${#BACKUPS[@]} > 0 )) && [[ -d "${BACKUPS[0]}" ]]; then
  echo ""
  log "Available backups (to restore, re-run with --restore-backup <path>):"
  for b in "${BACKUPS[@]}"; do
    [[ -d "$b" ]] && echo "  $b"
  done
fi

echo ""

# Handle CLAUDE.md specially: remove only the bootstrap section, not the whole file
remove_claude_md_section() {
  local dst="${CLAUDE_DIR}/CLAUDE.md"
  if [[ ! -f "$dst" ]]; then
    return
  fi

  local sentinel_begin="<!-- BEGIN bootstrap-claude-code -->"
  local sentinel_end="<!-- END bootstrap-claude-code -->"

  if grep -q "$sentinel_begin" "$dst" 2>/dev/null; then
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "[dry-run] Would remove bootstrap section from ~/.claude/CLAUDE.md"
      return
    fi
    python3 - "$dst" "$sentinel_begin" "$sentinel_end" <<'PYEOF'
import sys, re

dst_path, begin, end = sys.argv[1], sys.argv[2], sys.argv[3]

with open(dst_path) as f:
    content = f.read()

pattern = r'\n?' + re.escape(begin) + r'.*?' + re.escape(end) + r'\n?'
updated = re.sub(pattern, '', content, flags=re.DOTALL).strip()

if updated:
    with open(dst_path, 'w') as f:
        f.write(updated + '\n')
    print(f"Removed bootstrap section from {dst_path}")
else:
    import os
    os.remove(dst_path)
    print(f"CLAUDE.md was empty after removal — deleted")
PYEOF
    ok "Bootstrap section removed from ~/.claude/CLAUDE.md"
  else
    # No sentinel found — CLAUDE.md was not appended to, it was created wholesale
    dry rm "$dst"
    ok "Removed: ~/.claude/CLAUDE.md"
  fi
}

# Remove each installed file
for f in "${INSTALLED_FILES[@]}"; do
  if [[ "$f" == "${CLAUDE_DIR}/CLAUDE.md" ]]; then
    remove_claude_md_section
    continue
  fi

  if [[ -f "$f" ]]; then
    dry rm "$f"
    ok "Removed: $f"
  else
    log "Already absent: $f"
  fi
done

# Clean up empty hooks/commands directories if they're empty
for dir in "${CLAUDE_DIR}/hooks" "${CLAUDE_DIR}/commands"; do
  if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
    dry rmdir "$dir"
    ok "Removed empty directory: $dir"
  fi
done

echo ""
echo -e "${GREEN}${BOLD}Uninstall complete.${RESET}"

if (( ${#BACKUPS[@]} > 0 )) && [[ -d "${BACKUPS[0]}" ]]; then
  echo ""
  log "To restore your previous configuration:"
  echo "  ./uninstall.sh --restore-backup ${BACKUPS[-1]}"
fi
echo ""
