#!/usr/bin/env bats
# Integration tests for install.sh
# Each test runs the installer against an isolated temp HOME directory.
# No real ~/.claude is touched.
#
# Run with: bats tests/integration/test_install.bats

PROJECT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
INSTALL_SCRIPT="${PROJECT_DIR}/install.sh"

# ─── Helpers ─────────────────────────────────────────────────────────────────

setup() {
  FAKE_HOME="$(mktemp -d)"

  # Provide a stub claude binary so check_claude_cli() returns early
  mkdir -p "${FAKE_HOME}/bin"
  printf '#!/usr/bin/env bash\necho "claude stub"\n' > "${FAKE_HOME}/bin/claude"
  chmod +x "${FAKE_HOME}/bin/claude"

  # On Windows, python3 may be a broken App Execution Alias.
  # Provide a working stub that delegates to `python` (the real interpreter).
  if ! python3 -c "import sys" &>/dev/null 2>&1 && command -v python &>/dev/null; then
    printf '#!/usr/bin/env bash\nexec python "$@"\n' > "${FAKE_HOME}/bin/python3"
    chmod +x "${FAKE_HOME}/bin/python3"
  fi

  FAKE_PATH="${FAKE_HOME}/bin:${PATH}"
  CLAUDE_DIR="${FAKE_HOME}/.claude"
}

teardown() {
  rm -rf "$FAKE_HOME"
}

# Run install.sh with HOME and PATH redirected to the test sandbox.
# Extra flags (e.g. --minimal, --force) can be passed as arguments.
run_installer() {
  HOME="$FAKE_HOME" PATH="$FAKE_PATH" bash "$INSTALL_SCRIPT" --unattended "$@"
}

# Run install.sh in --verify-only mode against the sandbox.
run_verify() {
  HOME="$FAKE_HOME" PATH="$FAKE_PATH" bash "$INSTALL_SCRIPT" --unattended --verify
}

# Invoke python3, preferring the working stub in the sandbox over the system one.
py3() {
  if [ -x "${FAKE_HOME}/bin/python3" ]; then
    "${FAKE_HOME}/bin/python3" "$@"
  else
    python3 "$@"
  fi
}

skip_if_no_python3() {
  if ! py3 -c "import sys" &>/dev/null 2>&1; then
    skip "python3 not working in this environment"
  fi
}

# ─── AC1: Fresh install ───────────────────────────────────────────────────────

@test "fresh install: core files are created" {
  run run_installer
  [ "$status" -eq 0 ]
  [ -f "${CLAUDE_DIR}/settings.json" ]
  [ -f "${CLAUDE_DIR}/CLAUDE.md" ]
  [ -f "${CLAUDE_DIR}/keybindings.json" ]
  [ -f "${CLAUDE_DIR}/memory/MEMORY.md" ]
}

@test "fresh install: verify phase exits 0" {
  run_installer
  run run_verify
  [ "$status" -eq 0 ]
}

@test "fresh install: hooks are installed and executable" {
  run run_installer
  [ "$status" -eq 0 ]
  [ -x "${CLAUDE_DIR}/hooks/pre-tool-use.sh" ]
  [ -x "${CLAUDE_DIR}/hooks/post-tool-use.sh" ]
  [ -x "${CLAUDE_DIR}/hooks/stop.sh" ]
  [ -x "${CLAUDE_DIR}/hooks/session-start.sh" ]
}

@test "fresh install: slash commands are installed" {
  run run_installer
  [ "$status" -eq 0 ]
  [ -f "${CLAUDE_DIR}/commands/commit.md" ]
  [ -f "${CLAUDE_DIR}/commands/fix-bug.md" ]
  [ -f "${CLAUDE_DIR}/commands/review-pr.md" ]
}

# ─── AC2: Existing settings.json — permissions merged ────────────────────────

@test "merge: user allow entries are preserved in existing settings.json" {
  skip_if_no_python3
  mkdir -p "$CLAUDE_DIR"
  printf '{"permissions":{"allow":["Bash(custom-cmd*)"],"deny":[]}}\n' \
    > "${CLAUDE_DIR}/settings.json"

  run run_installer
  [ "$status" -eq 0 ]

  py3 - "${CLAUDE_DIR}/settings.json" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
assert "Bash(custom-cmd*)" in d["permissions"]["allow"], \
    "Original allow entry was lost after merge"
PY
}

@test "merge: template allow entries are added to existing settings.json" {
  skip_if_no_python3
  mkdir -p "$CLAUDE_DIR"
  printf '{"permissions":{"allow":[],"deny":[]}}\n' \
    > "${CLAUDE_DIR}/settings.json"

  run run_installer
  [ "$status" -eq 0 ]

  # Template adds at least one allow entry; resulting list must be non-empty
  py3 - "${CLAUDE_DIR}/settings.json" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
assert len(d["permissions"]["allow"]) > 0, "No allow entries after merge"
PY
}

# ─── AC3: Backup ─────────────────────────────────────────────────────────────

@test "backup: timestamped backup directory is created for existing files" {
  mkdir -p "$CLAUDE_DIR"
  echo '{"model":"pre-existing"}' > "${CLAUDE_DIR}/settings.json"

  run run_installer
  [ "$status" -eq 0 ]

  backup_count=$(ls -d "${CLAUDE_DIR}/bootstrapper-backup-"* 2>/dev/null | wc -l)
  [ "$backup_count" -ge 1 ]
}

@test "backup: original settings.json content is preserved in backup" {
  mkdir -p "$CLAUDE_DIR"
  printf '{"model":"pre-existing","permissions":{"allow":[],"deny":[]}}\n' \
    > "${CLAUDE_DIR}/settings.json"

  run run_installer
  [ "$status" -eq 0 ]

  backup_dir=$(ls -d "${CLAUDE_DIR}/bootstrapper-backup-"* 2>/dev/null | head -1)
  [ -f "${backup_dir}/settings.json" ]
  grep -q '"pre-existing"' "${backup_dir}/settings.json"
}

# ─── AC4: --minimal ──────────────────────────────────────────────────────────

@test "minimal: core files are still installed" {
  run run_installer --minimal
  [ "$status" -eq 0 ]
  [ -f "${CLAUDE_DIR}/settings.json" ]
  [ -f "${CLAUDE_DIR}/CLAUDE.md" ]
}

@test "minimal: hooks directory has no hook scripts" {
  run run_installer --minimal
  [ "$status" -eq 0 ]
  [ ! -f "${CLAUDE_DIR}/hooks/pre-tool-use.sh" ]
  [ ! -f "${CLAUDE_DIR}/hooks/post-tool-use.sh" ]
  [ ! -f "${CLAUDE_DIR}/hooks/stop.sh" ]
}

@test "minimal: slash commands are not installed" {
  run run_installer --minimal
  [ "$status" -eq 0 ]
  [ ! -f "${CLAUDE_DIR}/commands/commit.md" ]
}

# ─── AC5: CLAUDE.md sentinel — updated in-place, not duplicated ──────────────

@test "sentinel: existing bootstrap section is updated, not duplicated" {
  skip_if_no_python3
  mkdir -p "$CLAUDE_DIR"
  cat > "${CLAUDE_DIR}/CLAUDE.md" <<'EOF'
# My Notes

<!-- BEGIN bootstrap-claude-code -->
old bootstrap content
<!-- END bootstrap-claude-code -->
EOF

  run run_installer
  [ "$status" -eq 0 ]

  count=$(grep -c '<!-- BEGIN bootstrap-claude-code -->' "${CLAUDE_DIR}/CLAUDE.md")
  [ "$count" -eq 1 ]
}

@test "sentinel: stale content inside markers is replaced" {
  skip_if_no_python3
  mkdir -p "$CLAUDE_DIR"
  cat > "${CLAUDE_DIR}/CLAUDE.md" <<'EOF'
# My Notes

<!-- BEGIN bootstrap-claude-code -->
stale-marker-content-xyz
<!-- END bootstrap-claude-code -->
EOF

  run run_installer
  [ "$status" -eq 0 ]

  ! grep -q 'stale-marker-content-xyz' "${CLAUDE_DIR}/CLAUDE.md"
}

@test "sentinel: content before bootstrap section is preserved" {
  skip_if_no_python3
  mkdir -p "$CLAUDE_DIR"
  cat > "${CLAUDE_DIR}/CLAUDE.md" <<'EOF'
# My Custom Notes
My personal instructions here.

<!-- BEGIN bootstrap-claude-code -->
old content
<!-- END bootstrap-claude-code -->
EOF

  run run_installer
  [ "$status" -eq 0 ]

  grep -q 'My personal instructions here.' "${CLAUDE_DIR}/CLAUDE.md"
}

# ─── AC6: --force ────────────────────────────────────────────────────────────

@test "force: existing settings.json is overwritten without prompting" {
  mkdir -p "$CLAUDE_DIR"
  # Write a settings file with a distinctive value that the template won't contain
  printf '{"_force_test_marker":"force-overwrite-check","permissions":{"allow":[],"deny":[]}}\n' \
    > "${CLAUDE_DIR}/settings.json"

  run run_installer --force
  [ "$status" -eq 0 ]

  ! grep -q '"force-overwrite-check"' "${CLAUDE_DIR}/settings.json"
}

@test "force: existing hook files are overwritten" {
  mkdir -p "${CLAUDE_DIR}/hooks"
  echo "# old hook" > "${CLAUDE_DIR}/hooks/pre-tool-use.sh"
  chmod +x "${CLAUDE_DIR}/hooks/pre-tool-use.sh"

  run run_installer --force
  [ "$status" -eq 0 ]

  # The file should exist and no longer contain only the old stub content
  [ -f "${CLAUDE_DIR}/hooks/pre-tool-use.sh" ]
  ! grep -qx '# old hook' "${CLAUDE_DIR}/hooks/pre-tool-use.sh"
}
