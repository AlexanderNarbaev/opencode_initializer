#!/usr/bin/env bash
# Test cockpit binary — builds from source if the installer hasn't run yet.
# CI runners don't execute 31-cockpit.sh, so build src/cockpit/main.go here.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

TESTS_PASS=0; TESTS_FAIL=0

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1)); else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $desc" >&2; fi
}

BIN="$HOME/.local/bin/cockpit"

# Build from source when the binary isn't already installed (e.g. fresh CI runner).
if [ ! -f "$BIN" ] && command -v go &>/dev/null && [ -d "$PROJECT_DIR/src/cockpit" ]; then
  mkdir -p "$(dirname "$BIN")"
  ( cd "$PROJECT_DIR/src/cockpit" && CGO_ENABLED=0 go build -ldflags="-s -w" -o "$BIN" . ) &>/dev/null || true
fi

assert "cockpit binary exists" "[ -f '$BIN' ]"
assert "cockpit is executable" "[ -x '$BIN' ]"
assert "cockpit is ELF binary" "file '$BIN' | grep -q ELF"
echo "test_cockpit: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
