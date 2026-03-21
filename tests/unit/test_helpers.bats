#!/usr/bin/env bats
# Unit tests for lib/helpers.sh
# Run with: bats tests/unit/test_helpers.bats

PROJECT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
FIXTURES_DIR="${PROJECT_DIR}/tests/fixtures"

setup() {
  source "${PROJECT_DIR}/lib/helpers.sh"
  # Reset state variables before each test
  DRY_RUN=false
  FORCE=false
  UNATTENDED=false
}

# ─── dry() ───────────────────────────────────────────────────────────────────

@test "dry: executes command when DRY_RUN=false" {
  DRY_RUN=false
  tmp="$(mktemp)"
  dry touch "$tmp"
  [ -f "$tmp" ]
  rm -f "$tmp"
}

@test "dry: does not execute command when DRY_RUN=true" {
  DRY_RUN=true
  tmp="$(mktemp -u)"  # generate path without creating file
  dry touch "$tmp"
  [ ! -f "$tmp" ]
}

@test "dry: prints dry-run message when DRY_RUN=true" {
  DRY_RUN=true
  run dry echo "hello"
  [[ "$output" == *"dry-run"* ]]
  [[ "$output" == *"echo hello"* ]]
}

@test "dry: returns exit code of wrapped command when DRY_RUN=false" {
  DRY_RUN=false
  run dry true
  [ "$status" -eq 0 ]
  run dry false
  [ "$status" -eq 1 ]
}

@test "dry: returns 0 when DRY_RUN=true regardless of command" {
  DRY_RUN=true
  run dry false
  [ "$status" -eq 0 ]
}

# ─── confirm() ───────────────────────────────────────────────────────────────

@test "confirm: returns 0 when UNATTENDED=true" {
  UNATTENDED=true
  run confirm "Proceed?"
  [ "$status" -eq 0 ]
}

@test "confirm: returns 0 when FORCE=true" {
  FORCE=true
  run confirm "Proceed?"
  [ "$status" -eq 0 ]
}

@test "confirm: returns 0 for 'y' input" {
  UNATTENDED=false
  FORCE=false
  run bash -c "source '${PROJECT_DIR}/lib/helpers.sh'; echo y | confirm 'OK?'"
  [ "$status" -eq 0 ]
}

@test "confirm: returns 0 for 'Y' input" {
  UNATTENDED=false
  FORCE=false
  run bash -c "source '${PROJECT_DIR}/lib/helpers.sh'; echo Y | confirm 'OK?'"
  [ "$status" -eq 0 ]
}

@test "confirm: returns non-zero for 'n' input" {
  UNATTENDED=false
  FORCE=false
  run bash -c "source '${PROJECT_DIR}/lib/helpers.sh'; echo n | confirm 'OK?'"
  [ "$status" -ne 0 ]
}

@test "confirm: returns non-zero for empty input" {
  UNATTENDED=false
  FORCE=false
  run bash -c "source '${PROJECT_DIR}/lib/helpers.sh'; echo '' | confirm 'OK?'"
  [ "$status" -ne 0 ]
}

# ─── detect_pkg_manager() ────────────────────────────────────────────────────

@test "detect_pkg_manager: returns a known value" {
  result="$(detect_pkg_manager)"
  [[ "$result" == "brew" || "$result" == "apt" || "$result" == "dnf" || \
     "$result" == "pacman" || "$result" == "unknown" ]]
}

@test "detect_pkg_manager: returns unknown when no manager found" {
  # Override PATH to hide all package managers
  result="$(PATH=/dev/null detect_pkg_manager)"
  [ "$result" = "unknown" ]
}

# ─── merge_settings_json() ───────────────────────────────────────────────────

@test "merge_settings_json: target scalars win" {
  skip_if_no_python3
  result="$(merge_settings_json "${FIXTURES_DIR}/settings_source.json" \
                                 "${FIXTURES_DIR}/settings_target.json")"
  echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['model']=='claude-sonnet-4'"
}

@test "merge_settings_json: source-only scalar is added" {
  skip_if_no_python3
  result="$(merge_settings_json "${FIXTURES_DIR}/settings_source.json" \
                                 "${FIXTURES_DIR}/settings_target.json")"
  echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['newScalar']=='from-source'"
}

@test "merge_settings_json: allow lists are unioned" {
  skip_if_no_python3
  result="$(merge_settings_json "${FIXTURES_DIR}/settings_source.json" \
                                 "${FIXTURES_DIR}/settings_target.json")"
  echo "$result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
allow = d['permissions']['allow']
assert 'Bash(git*)' in allow
assert 'Bash(npm*)' in allow
"
}

@test "merge_settings_json: output is valid JSON" {
  skip_if_no_python3
  result="$(merge_settings_json "${FIXTURES_DIR}/settings_source.json" \
                                 "${FIXTURES_DIR}/settings_target.json")"
  echo "$result" | python3 -m json.tool > /dev/null
}

# ─── merge_keybindings_json() ────────────────────────────────────────────────

@test "merge_keybindings_json: existing key not overwritten" {
  skip_if_no_python3
  result="$(merge_keybindings_json "${FIXTURES_DIR}/keybindings_source.json" \
                                    "${FIXTURES_DIR}/keybindings_target.json")"
  echo "$result" | python3 -c "
import sys, json
bindings = json.load(sys.stdin)
by_key = {b['key']: b for b in bindings}
assert by_key['ctrl+a']['command'] == 'custom-cmd-a'
"
}

@test "merge_keybindings_json: new bindings added from source" {
  skip_if_no_python3
  result="$(merge_keybindings_json "${FIXTURES_DIR}/keybindings_source.json" \
                                    "${FIXTURES_DIR}/keybindings_target.json")"
  echo "$result" | python3 -c "
import sys, json
bindings = json.load(sys.stdin)
keys = [b['key'] for b in bindings]
assert 'ctrl+b' in keys
assert 'ctrl+c' in keys
"
}

@test "merge_keybindings_json: output is valid JSON" {
  skip_if_no_python3
  result="$(merge_keybindings_json "${FIXTURES_DIR}/keybindings_source.json" \
                                    "${FIXTURES_DIR}/keybindings_target.json")"
  echo "$result" | python3 -m json.tool > /dev/null
}

# ─── Helpers ─────────────────────────────────────────────────────────────────

skip_if_no_python3() {
  if ! command -v python3 &>/dev/null; then
    skip "python3 not available"
  fi
}
