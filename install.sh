#!/usr/bin/env bash
# install.sh — Claude Code Bootstrapper
# Sets up best-practice ~/.claude/ configurations for new Claude Code users.
# Usage: ./install.sh [--dry-run] [--force] [--minimal] [--unattended] [--verify]

set -euo pipefail

# ─── Constants ──────────────────────────────────────────────────────────────

BOOTSTRAPPER_VERSION="1.0.0"
CLAUDE_DIR="${HOME}/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${CLAUDE_DIR}/bootstrapper-backup-${TIMESTAMP}"
VERSION_FILE="${CLAUDE_DIR}/.bootstrapper-version"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# Load shared helpers (dry, confirm, detect_pkg_manager, merge_*_json)
# shellcheck source=lib/helpers.sh
source "${SCRIPT_DIR}/lib/helpers.sh"

# ─── Flags ───────────────────────────────────────────────────────────────────

DRY_RUN=false
FORCE=false
MINIMAL=false
UNATTENDED=false
VERIFY_ONLY=false

# ─── Utilities ───────────────────────────────────────────────────────────────
# dry(), confirm(), detect_pkg_manager(), merge_settings_json(), merge_keybindings_json()
# are provided by lib/helpers.sh (sourced above).

log()     { echo -e "${BLUE}[info]${RESET}  $*"; }
ok()      { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
error()   { echo -e "${RED}[error]${RESET} $*" >&2; }
heading() { echo -e "\n${BOLD}$*${RESET}"; }

# Attempt to install a package via detected package manager
install_package() {
  local pkg_name="$1"
  local brew_name="${2:-$pkg_name}"
  local apt_name="${3:-$pkg_name}"
  local dnf_name="${4:-$apt_name}"
  local pacman_name="${5:-$apt_name}"
  local pkg_mgr
  pkg_mgr="$(detect_pkg_manager)"

  log "Attempting to install ${pkg_name}..."

  case "$pkg_mgr" in
    brew)
      brew install "$brew_name"
      ;;
    apt)
      sudo apt-get install -y "$apt_name"
      ;;
    dnf)
      sudo dnf install -y "$dnf_name"
      ;;
    pacman)
      sudo pacman -S --noconfirm "$pacman_name"
      ;;
    *)
      error "No supported package manager found. Please install ${pkg_name} manually."
      return 1
      ;;
  esac
}

# ─── Arg Parsing ─────────────────────────────────────────────────────────────

for arg in "$@"; do
  case "$arg" in
    --dry-run)     DRY_RUN=true ;;
    --force)       FORCE=true ;;
    --minimal)     MINIMAL=true ;;
    --unattended)  UNATTENDED=true ;;
    --verify)      VERIFY_ONLY=true ;;
    --help|-h)
      echo "Usage: $0 [--dry-run] [--force] [--minimal] [--unattended] [--verify]"
      echo ""
      echo "  --dry-run     Print what would happen without making any changes"
      echo "  --force       Overwrite existing files without prompting"
      echo "  --minimal     Install only settings.json and CLAUDE.md (skip hooks/commands)"
      echo "  --unattended  Accept all defaults, no interactive prompts"
      echo "  --verify      Only verify existing install, don't install anything"
      exit 0
      ;;
    *)
      error "Unknown argument: $arg"
      exit 1
      ;;
  esac
done

# ─── Phase 1: Preflight Checks ───────────────────────────────────────────────

check_bash_version() {
  if (( BASH_VERSINFO[0] >= 4 )); then
    ok "Bash version: $BASH_VERSION"
    return 0
  fi

  warn "Bash 4+ required (found: $BASH_VERSION)"

  if [[ "$(uname)" == "Darwin" ]]; then
    if confirm "Install bash via Homebrew? (brew install bash)"; then
      if ! command -v brew &>/dev/null; then
        error "Homebrew not found. Install it from https://brew.sh then re-run this script."
        exit 1
      fi
      brew install bash
      warn "Bash upgraded. Please re-run this script with the new bash:"
      warn "  /usr/local/bin/bash $0 $@"
      exit 0
    else
      error "Bash 4+ is required. Aborting."
      exit 1
    fi
  else
    if confirm "Install bash via package manager?"; then
      install_package "bash" || exit 1
      warn "Bash upgraded. Please re-run this script."
      exit 0
    else
      error "Bash 4+ is required. Aborting."
      exit 1
    fi
  fi
}

check_claude_cli() {
  if command -v claude &>/dev/null; then
    ok "claude CLI found: $(command -v claude)"
    return 0
  fi

  warn "claude CLI not found on PATH."
  echo ""
  echo "  Claude Code can be installed via:"
  echo "    npm install -g @anthropic-ai/claude-code"
  echo "  Or downloaded from: https://claude.ai/download"
  echo ""

  if confirm "Install Claude Code now? (requires npm/Node.js)"; then
    if ! command -v npm &>/dev/null; then
      warn "npm not found. Node.js is required to install Claude Code via npm."
      if confirm "Install Node.js via package manager?"; then
        local pkg_mgr
        pkg_mgr="$(detect_pkg_manager)"
        case "$pkg_mgr" in
          brew)   brew install node ;;
          apt)    sudo apt-get install -y nodejs npm ;;
          dnf)    sudo dnf install -y nodejs npm ;;
          pacman) sudo pacman -S --noconfirm nodejs npm ;;
          *)
            error "Cannot auto-install Node.js. Install from https://nodejs.org then re-run."
            warn "Continuing without Claude Code — configs will be pre-staged."
            return 0
            ;;
        esac
      else
        warn "Continuing without Claude Code — configs will be pre-staged."
        return 0
      fi
    fi
    npm install -g @anthropic-ai/claude-code
    ok "Claude Code installed: $(command -v claude)"
  else
    warn "Continuing without Claude Code — configs will be pre-staged for when you install it."
  fi
}

check_python3() {
  if command -v python3 &>/dev/null; then
    ok "python3 found: $(command -v python3)"
    return 0
  fi

  warn "python3 not found. It is used for JSON merging (settings.json, keybindings.json)."
  echo "  Without python3, existing files will be overwritten rather than merged."
  echo ""

  if confirm "Install python3 via package manager?"; then
    install_package "python3" "python3" "python3" || {
      warn "Could not install python3. Continuing — existing configs will be overwritten."
      return 0
    }
    ok "python3 installed: $(command -v python3)"
  else
    warn "Continuing without python3 — existing configs will be overwritten if present."
  fi
}

preflight() {
  heading "Phase 1: Preflight checks"

  check_bash_version

  # Detect OS / WSL
  if grep -qi microsoft /proc/version 2>/dev/null; then
    OS="wsl"
    warn "WSL detected. Configs will be installed to Linux home: ${CLAUDE_DIR}"
    warn "Make sure Claude Code is running in WSL (not Windows) to pick up these configs."
  elif [[ "$(uname)" == "Darwin" ]]; then
    OS="macos"
    ok "OS: macOS"
  else
    OS="linux"
    ok "OS: Linux"
  fi

  check_claude_cli
  check_python3

  # Writable home
  if [[ ! -w "$HOME" ]]; then
    error "\$HOME is not writable: $HOME"
    exit 1
  fi
  ok "Home directory is writable: $HOME"

  # Templates dir
  if [[ ! -d "$TEMPLATES_DIR" ]]; then
    error "Templates directory not found: $TEMPLATES_DIR"
    error "Run this script from the bootstrap-claude-code project root."
    exit 1
  fi
  ok "Templates directory found: $TEMPLATES_DIR"

  # Existing install check
  if [[ -f "$VERSION_FILE" ]]; then
    local existing_version
    existing_version="$(cat "$VERSION_FILE")"
    if [[ "$existing_version" == "$BOOTSTRAPPER_VERSION" ]]; then
      warn "Already installed at version $existing_version."
      if ! confirm "Reinstall?"; then
        log "Skipping. Use --force to reinstall without prompting."
        exit 0
      fi
    else
      log "Upgrading from version $existing_version → $BOOTSTRAPPER_VERSION"
    fi
  fi
}

# ─── Phase 2: Backup ─────────────────────────────────────────────────────────

backup_existing() {
  heading "Phase 2: Backup existing configs"

  if [[ ! -d "$CLAUDE_DIR" ]]; then
    log "No existing ~/.claude/ directory. Skipping backup."
    return 0
  fi

  local backed_up=false
  local files_to_backup=(
    "settings.json"
    "CLAUDE.md"
    "keybindings.json"
  )
  local dirs_to_backup=(
    "hooks"
    "commands"
    "memory"
  )

  for f in "${files_to_backup[@]}"; do
    if [[ -f "${CLAUDE_DIR}/${f}" ]]; then
      dry mkdir -p "$BACKUP_DIR"
      dry cp "${CLAUDE_DIR}/${f}" "${BACKUP_DIR}/${f}"
      ok "Backed up: ~/.claude/${f}"
      backed_up=true
    fi
  done

  for d in "${dirs_to_backup[@]}"; do
    if [[ -d "${CLAUDE_DIR}/${d}" ]]; then
      dry mkdir -p "$BACKUP_DIR"
      dry cp -r "${CLAUDE_DIR}/${d}" "${BACKUP_DIR}/${d}"
      ok "Backed up: ~/.claude/${d}/"
      backed_up=true
    fi
  done

  if [[ "$backed_up" == "true" ]]; then
    log "Backup location: $BACKUP_DIR"
  fi
}

# ─── Phase 3: Directory Setup ────────────────────────────────────────────────

setup_dirs() {
  heading "Phase 3: Setting up directory structure"

  local dirs=(
    "$CLAUDE_DIR"
    "${CLAUDE_DIR}/hooks"
    "${CLAUDE_DIR}/memory"
    "${CLAUDE_DIR}/commands"
    "${CLAUDE_DIR}/plans"
  )

  for d in "${dirs[@]}"; do
    dry mkdir -p "$d"
    ok "Directory ready: $d"
  done
}

# ─── Phase 4: Install Templates ──────────────────────────────────────────────

# merge_settings_json() and merge_keybindings_json() provided by lib/helpers.sh

install_settings_json() {
  local src="${TEMPLATES_DIR}/settings.json"
  local dst="${CLAUDE_DIR}/settings.json"

  log "Installing settings.json..."

  if [[ ! -f "$src" ]]; then
    warn "Template not found: $src — skipping"
    return
  fi

  if [[ -f "$dst" && "$FORCE" != "true" ]]; then
    log "Merging with existing settings.json"
    local merged
    merged="$(merge_settings_json "$src" "$dst")"
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "[dry-run] Would write merged settings.json to $dst"
    else
      echo "$merged" > "$dst"
    fi
  else
    dry cp "$src" "$dst"
  fi
  ok "settings.json installed"
}

install_claude_md() {
  local src="${TEMPLATES_DIR}/CLAUDE.md"
  local dst="${CLAUDE_DIR}/CLAUDE.md"
  local sentinel_begin="<!-- BEGIN bootstrap-claude-code -->"
  local sentinel_end="<!-- END bootstrap-claude-code -->"

  log "Installing CLAUDE.md..."

  if [[ ! -f "$src" ]]; then
    warn "Template not found: $src — skipping"
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] Would append/update bootstrap section in $dst"
    return
  fi

  if [[ -f "$dst" ]]; then
    if grep -q "$sentinel_begin" "$dst"; then
      # Update existing bootstrap section
      if command -v python3 &>/dev/null; then
        python3 "${SCRIPT_DIR}/lib/update_claude_md.py" "$dst" "$sentinel_begin" "$sentinel_end" "$src"
        ok "CLAUDE.md updated (existing bootstrap section replaced)"
      else
        warn "python3 not found — cannot update existing bootstrap section. Remove the sentinel manually and re-run."
        return
      fi
    else
      # Append new bootstrap section
      {
        echo ""
        echo "$sentinel_begin"
        cat "$src"
        echo "$sentinel_end"
      } >> "$dst"
      ok "CLAUDE.md updated (bootstrap section appended)"
    fi
  else
    {
      echo "$sentinel_begin"
      cat "$src"
      echo "$sentinel_end"
    } > "$dst"
    ok "CLAUDE.md created"
  fi
}

install_keybindings() {
  local src="${TEMPLATES_DIR}/keybindings.json"
  local dst="${CLAUDE_DIR}/keybindings.json"

  log "Installing keybindings.json..."

  if [[ ! -f "$src" ]]; then
    warn "Template not found: $src — skipping"
    return
  fi

  if [[ -f "$dst" && "$FORCE" != "true" ]]; then
    local merged
    merged="$(merge_keybindings_json "$src" "$dst")"
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "[dry-run] Would write merged keybindings.json to $dst"
    else
      echo "$merged" > "$dst"
    fi
  else
    dry cp "$src" "$dst"
  fi
  ok "keybindings.json installed"
}

install_memory() {
  local src="${TEMPLATES_DIR}/memory/MEMORY.md"
  local dst="${CLAUDE_DIR}/memory/MEMORY.md"

  log "Installing memory/MEMORY.md..."

  if [[ ! -f "$src" ]]; then
    warn "Template not found: $src — skipping"
    return
  fi

  if [[ -f "$dst" ]]; then
    log "memory/MEMORY.md already exists — skipping (never overwrite user memory)"
  else
    dry cp "$src" "$dst"
    ok "memory/MEMORY.md created"
  fi
}

install_hooks() {
  if [[ "$MINIMAL" == "true" ]]; then
    log "Skipping hooks (--minimal mode)"
    return
  fi

  log "Installing hooks..."

  local hooks_src="${TEMPLATES_DIR}/hooks"
  if [[ ! -d "$hooks_src" ]]; then
    warn "No hooks/ template directory found — skipping"
    return
  fi

  for hook_file in "${hooks_src}"/*.sh; do
    local hook_name
    hook_name="$(basename "$hook_file")"
    local dst="${CLAUDE_DIR}/hooks/${hook_name}"

    dry cp "$hook_file" "$dst"
    dry chmod +x "$dst"
    ok "Hook installed: ~/.claude/hooks/${hook_name}"
  done

  if [[ "$DRY_RUN" != "true" ]] && command -v python3 &>/dev/null; then
    register_hooks_in_settings
  elif [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] Would register hooks in ~/.claude/settings.json"
  else
    warn "python3 not found — hooks not registered in settings.json. Add them manually per docs/04-hooks.md"
  fi
}

register_hooks_in_settings() {
  local settings="${CLAUDE_DIR}/settings.json"
  local hooks_dir="${CLAUDE_DIR}/hooks"

  python3 - "$settings" "$hooks_dir" <<'PYEOF'
import sys, json, os

settings_path, hooks_dir = sys.argv[1], sys.argv[2]

with open(settings_path) as f:
    settings = json.load(f)

if 'hooks' not in settings:
    settings['hooks'] = {}

hook_map = {
    'PreToolUse':   'pre-tool-use.sh',
    'PostToolUse':  'post-tool-use.sh',
    'Stop':         'stop.sh',
    'SessionStart': 'session-start.sh',
}

for event, script in hook_map.items():
    script_path = os.path.join(hooks_dir, script)
    if not os.path.exists(script_path):
        continue
    hook_entry = [{"type": "command", "command": script_path}]
    if event not in settings['hooks']:
        if event in ('PreToolUse', 'PostToolUse'):
            settings['hooks'][event] = [{"matcher": "*", "hooks": hook_entry}]
        else:
            settings['hooks'][event] = [{"hooks": hook_entry}]

with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
PYEOF
  ok "Hooks registered in settings.json"
}

install_commands() {
  if [[ "$MINIMAL" == "true" ]]; then
    log "Skipping commands (--minimal mode)"
    return
  fi

  log "Installing slash commands..."

  local commands_src="${TEMPLATES_DIR}/commands"
  if [[ ! -d "$commands_src" ]]; then
    warn "No commands/ template directory found — skipping"
    return
  fi

  for cmd_file in "${commands_src}"/*.md; do
    local cmd_name
    cmd_name="$(basename "$cmd_file")"
    local dst="${CLAUDE_DIR}/commands/${cmd_name}"

    if [[ -f "$dst" && "$FORCE" != "true" ]]; then
      log "Skipping ~/.claude/commands/${cmd_name} (already exists)"
    else
      dry cp "$cmd_file" "$dst"
      ok "Command installed: ~/.claude/commands/${cmd_name}"
    fi
  done
}

install_all() {
  heading "Phase 4: Installing templates"
  install_settings_json
  install_claude_md
  install_keybindings
  install_memory
  install_hooks
  install_commands
}

# ─── Phase 5: Verify ─────────────────────────────────────────────────────────

verify() {
  heading "Phase 5: Verification"

  local all_ok=true

  assert_exists() {
    local path="$1"
    local label="${2:-$path}"
    if [[ -f "$path" ]]; then
      ok "$label"
    else
      error "MISSING: $label"
      all_ok=false
    fi
  }

  assert_executable() {
    local path="$1"
    local label="${2:-$path}"
    if [[ -x "$path" ]]; then
      ok "$label (executable)"
    else
      error "NOT EXECUTABLE: $label"
      all_ok=false
    fi
  }

  assert_valid_json() {
    local path="$1"
    local label="${2:-$path}"
    if python3 -m json.tool "$path" &>/dev/null 2>&1; then
      ok "$label (valid JSON)"
    else
      error "INVALID JSON: $label"
      all_ok=false
    fi
  }

  assert_exists "${CLAUDE_DIR}/settings.json"   "~/.claude/settings.json"
  assert_exists "${CLAUDE_DIR}/CLAUDE.md"        "~/.claude/CLAUDE.md"
  assert_exists "${CLAUDE_DIR}/keybindings.json" "~/.claude/keybindings.json"
  assert_exists "${CLAUDE_DIR}/memory/MEMORY.md" "~/.claude/memory/MEMORY.md"

  if [[ "$MINIMAL" != "true" ]]; then
    assert_executable "${CLAUDE_DIR}/hooks/pre-tool-use.sh"   "~/.claude/hooks/pre-tool-use.sh"
    assert_executable "${CLAUDE_DIR}/hooks/post-tool-use.sh"  "~/.claude/hooks/post-tool-use.sh"
    assert_executable "${CLAUDE_DIR}/hooks/session-start.sh"  "~/.claude/hooks/session-start.sh"
    assert_executable "${CLAUDE_DIR}/hooks/stop.sh"           "~/.claude/hooks/stop.sh"
    assert_exists "${CLAUDE_DIR}/commands/commit.md"   "~/.claude/commands/commit.md"
    assert_exists "${CLAUDE_DIR}/commands/review-pr.md" "~/.claude/commands/review-pr.md"
    assert_exists "${CLAUDE_DIR}/commands/fix-bug.md"  "~/.claude/commands/fix-bug.md"
  fi

  if command -v python3 &>/dev/null; then
    assert_valid_json "${CLAUDE_DIR}/settings.json"    "~/.claude/settings.json"
    assert_valid_json "${CLAUDE_DIR}/keybindings.json" "~/.claude/keybindings.json"
  fi

  if [[ "$all_ok" == "true" ]]; then
    echo ""
    echo -e "${GREEN}${BOLD}All checks passed.${RESET}"
  else
    echo ""
    echo -e "${RED}${BOLD}Some checks failed. See errors above.${RESET}"
    return 1
  fi
}

write_version_marker() {
  if [[ "$DRY_RUN" != "true" ]]; then
    echo "$BOOTSTRAPPER_VERSION" > "$VERSION_FILE"
  fi
}

print_next_steps() {
  echo ""
  echo -e "${BOLD}Next steps:${RESET}"
  echo "  1. Open Claude Code:          claude"
  echo "  2. Read the user guide:       ${SCRIPT_DIR}/docs/00-overview.md"
  echo "  3. Customize your CLAUDE.md:  ${CLAUDE_DIR}/CLAUDE.md"
  echo "  4. Review permissions:        ${CLAUDE_DIR}/settings.json"
  if [[ -d "${BACKUP_DIR}" ]]; then
    echo "  5. Previous configs backed up: ${BACKUP_DIR}"
  fi
  echo ""
}

# ─── Main ────────────────────────────────────────────────────────────────────

main() {
  echo -e "${BOLD}Claude Code Bootstrapper v${BOOTSTRAPPER_VERSION}${RESET}"
  echo "────────────────────────────────────────"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}DRY RUN MODE — no changes will be made${RESET}\n"
  fi

  if [[ "$VERIFY_ONLY" == "true" ]]; then
    verify
    exit $?
  fi

  preflight
  backup_existing
  setup_dirs
  install_all
  write_version_marker
  verify
  print_next_steps
}

main "$@"
