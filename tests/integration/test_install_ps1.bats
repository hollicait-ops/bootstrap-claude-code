#!/usr/bin/env bats
# Integration tests for install.ps1 and uninstall.ps1 (Windows PowerShell)
# Tests are skipped automatically when pwsh is not available.
#
# Run with: bats tests/integration/test_install_ps1.bats

PROJECT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
INSTALL_PS1="${PROJECT_DIR}/install.ps1"
UNINSTALL_PS1="${PROJECT_DIR}/uninstall.ps1"

# ─── Helpers ─────────────────────────────────────────────────────────────────

setup() {
  if ! command -v pwsh &>/dev/null; then
    return  # will be skipped in each test
  fi

  FAKE_HOME="$(mktemp -d)"
  FAKE_CLAUDE_DIR="${FAKE_HOME}/.claude"

  # Provide a stub claude binary so check_claude_cli() returns early
  mkdir -p "${FAKE_HOME}/bin"
  printf '#!/usr/bin/env bash\necho "claude stub"\n' > "${FAKE_HOME}/bin/claude"
  chmod +x "${FAKE_HOME}/bin/claude"
}

teardown() {
  if [[ -n "${FAKE_HOME:-}" ]]; then
    rm -rf "$FAKE_HOME"
  fi
}

skip_if_no_pwsh() {
  if ! command -v pwsh &>/dev/null; then
    skip "pwsh not available"
  fi
}

# Run install.ps1 against the sandbox home directory.
# Extra flags (e.g. -Minimal, -Force) can be passed as arguments.
run_ps1_installer() {
  HOME="$FAKE_HOME" \
  USERPROFILE="$FAKE_HOME" \
  pwsh -NonInteractive -ExecutionPolicy Bypass -File "$INSTALL_PS1" \
    -Unattended "$@"
}

# Run install.ps1 in -Verify mode against the sandbox.
run_ps1_verify() {
  HOME="$FAKE_HOME" \
  USERPROFILE="$FAKE_HOME" \
  pwsh -NonInteractive -ExecutionPolicy Bypass -File "$INSTALL_PS1" \
    -Unattended -Verify
}

# Run uninstall.ps1 against the sandbox home directory.
run_ps1_uninstaller() {
  HOME="$FAKE_HOME" \
  USERPROFILE="$FAKE_HOME" \
  pwsh -NonInteractive -ExecutionPolicy Bypass -File "$UNINSTALL_PS1" \
    -Unattended "$@"
}

# ─── Install tests ────────────────────────────────────────────────────────────

@test "ps1 fresh install: core files are created" {
  skip_if_no_pwsh
  run run_ps1_installer
  [ "$status" -eq 0 ]
  [ -f "${FAKE_CLAUDE_DIR}/settings.json" ]
  [ -f "${FAKE_CLAUDE_DIR}/CLAUDE.md" ]
  [ -f "${FAKE_CLAUDE_DIR}/keybindings.json" ]
  [ -f "${FAKE_CLAUDE_DIR}/memory/MEMORY.md" ]
}

@test "ps1 fresh install: verify phase exits 0" {
  skip_if_no_pwsh
  run_ps1_installer
  run run_ps1_verify
  [ "$status" -eq 0 ]
}

@test "ps1 fresh install: hooks are installed" {
  skip_if_no_pwsh
  run run_ps1_installer
  [ "$status" -eq 0 ]
  [ -f "${FAKE_CLAUDE_DIR}/hooks/pre-tool-use.ps1" ]
  [ -f "${FAKE_CLAUDE_DIR}/hooks/post-tool-use.ps1" ]
  [ -f "${FAKE_CLAUDE_DIR}/hooks/stop.ps1" ]
  [ -f "${FAKE_CLAUDE_DIR}/hooks/session-start.ps1" ]
}

@test "ps1 fresh install: slash commands are installed" {
  skip_if_no_pwsh
  run run_ps1_installer
  [ "$status" -eq 0 ]
  [ -f "${FAKE_CLAUDE_DIR}/commands/commit.md" ]
  [ -f "${FAKE_CLAUDE_DIR}/commands/fix-bug.md" ]
  [ -f "${FAKE_CLAUDE_DIR}/commands/review-pr.md" ]
}

@test "ps1 fresh install: settings.json is valid JSON" {
  skip_if_no_pwsh
  run_ps1_installer
  run pwsh -NonInteractive -ExecutionPolicy Bypass -Command \
    "Get-Content '${FAKE_CLAUDE_DIR}/settings.json' | ConvertFrom-Json | Out-Null; exit 0"
  [ "$status" -eq 0 ]
}

@test "ps1 minimal install: only core files created, no hooks" {
  skip_if_no_pwsh
  run run_ps1_installer -Minimal
  [ "$status" -eq 0 ]
  [ -f "${FAKE_CLAUDE_DIR}/settings.json" ]
  [ -f "${FAKE_CLAUDE_DIR}/CLAUDE.md" ]
  [ ! -f "${FAKE_CLAUDE_DIR}/hooks/pre-tool-use.ps1" ]
}

@test "ps1 merge: user entries preserved in existing settings.json" {
  skip_if_no_pwsh
  mkdir -p "$FAKE_CLAUDE_DIR"
  printf '{"permissions":{"allow":["Bash(custom-cmd*)"],"deny":[]}}\n' \
    > "${FAKE_CLAUDE_DIR}/settings.json"

  run_ps1_installer

  # Check user allow entry was not removed
  run pwsh -NonInteractive -ExecutionPolicy Bypass -Command "
    \$s = Get-Content '${FAKE_CLAUDE_DIR}/settings.json' | ConvertFrom-Json
    if (\$s.permissions.allow -contains 'Bash(custom-cmd*)') { exit 0 } else { exit 1 }
  "
  [ "$status" -eq 0 ]
}

# ─── Uninstall tests ──────────────────────────────────────────────────────────

@test "ps1 uninstall: removes bootstrapper files" {
  skip_if_no_pwsh
  run_ps1_installer
  run run_ps1_uninstaller
  [ "$status" -eq 0 ]
  [ ! -f "${FAKE_CLAUDE_DIR}/hooks/pre-tool-use.ps1" ]
  [ ! -f "${FAKE_CLAUDE_DIR}/commands/commit.md" ]
}

@test "ps1 uninstall: preserves user-added files" {
  skip_if_no_pwsh
  run_ps1_installer
  # Create a user-added file that the uninstaller should not remove
  echo "my custom hook" > "${FAKE_CLAUDE_DIR}/hooks/my-custom-hook.ps1"

  run run_ps1_uninstaller
  [ "$status" -eq 0 ]
  [ -f "${FAKE_CLAUDE_DIR}/hooks/my-custom-hook.ps1" ]
}