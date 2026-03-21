#!/usr/bin/env bash
# tests/run-tests.sh — Run the full test suite (bash + Python + integration)
# Usage: ./tests/run-tests.sh [--unit] [--integration] [--all]
#
# Runs by default: Python unit tests (pytest) + BATS unit tests + BATS integration tests

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_DIR="${PROJECT_DIR}/tests"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

pass=0
fail=0
skip=0

header() { echo -e "\n${BOLD}$*${RESET}"; }
ok()     { echo -e "${GREEN}[pass]${RESET} $*"; ((pass++)) || true; }
err()    { echo -e "${RED}[fail]${RESET} $*"; ((fail++)) || true; }
warn()   { echo -e "${YELLOW}[skip]${RESET} $*"; ((skip++)) || true; }

# ─── Python unit tests ───────────────────────────────────────────────────────

header "Python unit tests (pytest)"

if ! command -v python3 &>/dev/null; then
  warn "python3 not found — skipping Python tests"
elif ! python3 -m pytest --version &>/dev/null 2>&1; then
  warn "pytest not found — install with: pip3 install pytest"
  warn "Skipping Python tests"
else
  if python3 -m pytest "${TESTS_DIR}/unit/test_merge_settings.py" \
                        "${TESTS_DIR}/unit/test_merge_keybindings.py" \
                        "${TESTS_DIR}/unit/test_update_claude_md.py" \
                        -v 2>&1; then
    ok "Python unit tests passed"
  else
    err "Python unit tests failed"
  fi
fi

# ─── BATS unit tests ─────────────────────────────────────────────────────────

header "BATS unit tests (bash helpers)"

if ! command -v bats &>/dev/null; then
  warn "bats not found — install with one of:"
  warn "  brew install bats-core"
  warn "  apt-get install bats"
  warn "  npm install -g bats"
  warn "Skipping BATS tests"
else
  if bats "${TESTS_DIR}/unit/test_helpers.bats" 2>&1; then
    ok "BATS unit tests passed"
  else
    err "BATS unit tests failed"
  fi
fi

# ─── BATS integration tests ──────────────────────────────────────────────────

header "BATS integration tests (installer phases)"

if ! command -v bats &>/dev/null; then
  warn "bats not found — skipping integration tests"
else
  if bats "${TESTS_DIR}/integration/test_install.bats" 2>&1; then
    ok "BATS integration tests passed"
  else
    err "BATS integration tests failed"
  fi
fi

# ─── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Results:${RESET} ${GREEN}${pass} passed${RESET}  ${RED}${fail} failed${RESET}  ${YELLOW}${skip} skipped${RESET}"

if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
