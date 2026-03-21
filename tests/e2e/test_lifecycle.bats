#!/usr/bin/env bats
# End-to-end tests: full install → verify → uninstall lifecycle
# Each test runs against an isolated temp HOME directory.
# No real ~/.claude is touched.
#
# Run with: bats tests/e2e/test_lifecycle.bats

PROJECT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
INSTALL_SCRIPT="${PROJECT_DIR}/install.sh"
UNINSTALL_SCRIPT="${PROJECT_DIR}/uninstall.sh"

# ─── Helpers ─────────────────────────────────────────────────────────────────

setup() {
  FAKE_HOME="$(mktemp -d)"

  mkdir -p "${FAKE_HOME}/bin"
  printf '#!/usr/bin/env bash\necho "claude stub"\n' > "${FAKE_HOME}/bin/claude"
  chmod +x "${FAKE_HOME}/bin/claude"

  # On Windows, python3 may be a broken App Execution Alias.
  if ! python3 -c "import sys" &>/dev/null && command -v python &>/dev/null; then
    printf '#!/usr/bin/env bash\nexec python "$@"\n' > "${FAKE_HOME}/bin/python3"
    chmod +x "${FAKE_HOME}/bin/python3"
  fi

  FAKE_PATH="${FAKE_HOME}/bin:${PATH}"
  CLAUDE_DIR="${FAKE_HOME}/.claude"
}

teardown() {
  rm -rf "$FAKE_HOME"
}

run_installer() {
  HOME="$FAKE_HOME" PATH="$FAKE_PATH" bash "$INSTALL_SCRIPT" --unattended "$@"
}

run_uninstaller() {
  HOME="$FAKE_HOME" PATH="$FAKE_PATH" bash "$UNINSTALL_SCRIPT" "$@"
}

run_verify() {
  HOME="$FAKE_HOME" PATH="$FAKE_PATH" bash "$INSTALL_SCRIPT" --unattended --verify
}

py3() {
  if [ -x "${FAKE_HOME}/bin/python3" ]; then
    "${FAKE_HOME}/bin/python3" "$@"
  else
    python3 "$@"
  fi
}

skip_if_no_python3() {
  if [ -x "${FAKE_HOME}/bin/python3" ]; then return; fi
  if ! python3 -c "import sys" &>/dev/null 2>&1; then
    skip "python3 not working in this environment"
  fi
}

# ─── Uninstall basics ────────────────────────────────────────────────────────

@test "lifecycle: uninstall exits 0 after a fresh install" {
  run_installer
  run run_uninstaller
  [ "$status" -eq 0 ]
}

@test "lifecycle: uninstall removes all bootstrapper files" {
  run_installer
  run run_uninstaller
  [ "$status" -eq 0 ]

  [ ! -f "${CLAUDE_DIR}/settings.json" ]
  [ ! -f "${CLAUDE_DIR}/keybindings.json" ]
  [ ! -f "${CLAUDE_DIR}/memory/MEMORY.md" ]
  [ ! -f "${CLAUDE_DIR}/hooks/pre-tool-use.sh" ]
  [ ! -f "${CLAUDE_DIR}/hooks/post-tool-use.sh" ]
  [ ! -f "${CLAUDE_DIR}/hooks/stop.sh" ]
  [ ! -f "${CLAUDE_DIR}/hooks/session-start.sh" ]
  [ ! -f "${CLAUDE_DIR}/commands/commit.md" ]
  [ ! -f "${CLAUDE_DIR}/commands/fix-bug.md" ]
  [ ! -f "${CLAUDE_DIR}/.bootstrapper-version" ]
}

@test "lifecycle: uninstall --dry-run leaves all installed files intact" {
  run_installer

  run run_uninstaller --dry-run
  [ "$status" -eq 0 ]

  [ -f "${CLAUDE_DIR}/settings.json" ]
  [ -f "${CLAUDE_DIR}/CLAUDE.md" ]
  [ -f "${CLAUDE_DIR}/keybindings.json" ]
  [ -f "${CLAUDE_DIR}/hooks/pre-tool-use.sh" ]
}

# ─── Directory cleanup ───────────────────────────────────────────────────────

@test "lifecycle: empty hooks directory is removed after uninstall" {
  run_installer
  run_uninstaller

  # Directory must be gone or, if it still exists, must be empty
  [ ! -d "${CLAUDE_DIR}/hooks" ] || [ -z "$(ls -A "${CLAUDE_DIR}/hooks" 2>/dev/null)" ]
}

@test "lifecycle: empty commands directory is removed after uninstall" {
  run_installer
  run_uninstaller

  [ ! -d "${CLAUDE_DIR}/commands" ] || [ -z "$(ls -A "${CLAUDE_DIR}/commands" 2>/dev/null)" ]
}

# ─── CLAUDE.md sentinel handling ─────────────────────────────────────────────

@test "lifecycle: CLAUDE.md bootstrap section is removed on uninstall" {
  skip_if_no_python3
  run_installer
  run_uninstaller

  # File must be gone entirely or no longer contain the sentinel
  [ ! -f "${CLAUDE_DIR}/CLAUDE.md" ] || \
    ! grep -q '<!-- BEGIN bootstrap-claude-code -->' "${CLAUDE_DIR}/CLAUDE.md"
}

@test "lifecycle: CLAUDE.md is deleted when it contained only the bootstrap section" {
  skip_if_no_python3
  # Fresh install with no pre-existing CLAUDE.md → file only has bootstrap content
  run_installer
  run_uninstaller

  [ ! -f "${CLAUDE_DIR}/CLAUDE.md" ]
}

@test "lifecycle: user content in CLAUDE.md is preserved after uninstall" {
  skip_if_no_python3
  mkdir -p "$CLAUDE_DIR"
  cat > "${CLAUDE_DIR}/CLAUDE.md" <<'EOF'
# My Custom Rules
Always use tabs for indentation.

<!-- BEGIN bootstrap-claude-code -->
old content
<!-- END bootstrap-claude-code -->
EOF

  run_installer
  run_uninstaller

  [ -f "${CLAUDE_DIR}/CLAUDE.md" ]
  grep -q 'Always use tabs for indentation.' "${CLAUDE_DIR}/CLAUDE.md"
}

# ─── Reinstall lifecycle ─────────────────────────────────────────────────────

@test "lifecycle: reinstall after uninstall exits 0" {
  run_installer
  run_uninstaller

  run run_installer
  [ "$status" -eq 0 ]
}

@test "lifecycle: reinstall after uninstall restores all core files" {
  run_installer
  run_uninstaller
  run_installer

  [ -f "${CLAUDE_DIR}/settings.json" ]
  [ -f "${CLAUDE_DIR}/CLAUDE.md" ]
  [ -f "${CLAUDE_DIR}/keybindings.json" ]
  [ -f "${CLAUDE_DIR}/memory/MEMORY.md" ]
}

@test "lifecycle: verify phase passes after reinstall following uninstall" {
  run_installer
  run_uninstaller
  run_installer

  run run_verify
  [ "$status" -eq 0 ]
}

# ─── Backup restoration ───────────────────────────────────────────────────────

@test "lifecycle: --restore-backup restores original settings.json" {
  # Seed an existing config so the installer creates a backup of it
  mkdir -p "$CLAUDE_DIR"
  printf '{"_original_marker":"restore-check","permissions":{"allow":[],"deny":[]}}\n' \
    > "${CLAUDE_DIR}/settings.json"

  run_installer

  backup_dir=$(ls -d "${CLAUDE_DIR}/bootstrapper-backup-"* 2>/dev/null | head -1)
  [ -d "$backup_dir" ]

  run run_uninstaller --restore-backup "$backup_dir"
  [ "$status" -eq 0 ]

  [ -f "${CLAUDE_DIR}/settings.json" ]
  grep -q '"restore-check"' "${CLAUDE_DIR}/settings.json"
}

@test "lifecycle: --restore-backup restores hook executability" {
  # Seed hooks directory in the backup source
  mkdir -p "${CLAUDE_DIR}/hooks"
  printf '#!/usr/bin/env bash\necho "user hook"\n' > "${CLAUDE_DIR}/hooks/pre-tool-use.sh"
  chmod +x "${CLAUDE_DIR}/hooks/pre-tool-use.sh"

  run_installer

  backup_dir=$(ls -d "${CLAUDE_DIR}/bootstrapper-backup-"* 2>/dev/null | head -1)
  [ -d "$backup_dir" ]

  run_uninstaller --restore-backup "$backup_dir"

  # Hooks directory from backup should have been restored with executable bits
  [ -f "${CLAUDE_DIR}/hooks/pre-tool-use.sh" ]
  [ -x "${CLAUDE_DIR}/hooks/pre-tool-use.sh" ]
}
