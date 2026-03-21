#!/usr/bin/env bash
# lib/helpers.sh — Shared helper functions for install.sh / uninstall.sh
# Source this file: source "${SCRIPT_DIR}/lib/helpers.sh"

_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PROJECT_DIR="$(cd "${_HELPERS_DIR}/.." && pwd)"

# ─── Dry-run wrapper ──────────────────────────────────────────────────────────
# Requires: DRY_RUN variable (default: false)
dry() {
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo -e "${YELLOW:-}[dry-run]${RESET:-} Would run: $*"
    return 0
  fi
  "$@"
}

# ─── Interactive confirmation ─────────────────────────────────────────────────
# Requires: UNATTENDED and FORCE variables (default: false)
confirm() {
  local prompt="${1:-Continue?}"
  if [[ "${UNATTENDED:-false}" == "true" || "${FORCE:-false}" == "true" ]]; then
    return 0
  fi
  read -r -p "$(echo -e "${YELLOW:-}?${RESET:-} ${prompt} [y/N] ")" reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# ─── Package manager detection ───────────────────────────────────────────────
detect_pkg_manager() {
  if command -v brew &>/dev/null; then
    echo "brew"
  elif command -v apt-get &>/dev/null; then
    echo "apt"
  elif command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  else
    echo "unknown"
  fi
}

# ─── JSON merge helpers ───────────────────────────────────────────────────────
# Merge two settings.json files: target gets values from source non-destructively.
# Prints merged JSON to stdout.
merge_settings_json() {
  local source="$1"
  local target="$2"

  if command -v python3 &>/dev/null; then
    python3 "${_PROJECT_DIR}/lib/merge_settings.py" "$source" "$target"
  else
    cat "$source"
  fi
}

# Merge keybindings: only add bindings whose key slot is unused in target.
# Prints merged JSON to stdout.
merge_keybindings_json() {
  local source="$1"
  local target="$2"

  if command -v python3 &>/dev/null; then
    python3 "${_PROJECT_DIR}/lib/merge_keybindings.py" "$source" "$target"
  else
    cat "$source"
  fi
}
