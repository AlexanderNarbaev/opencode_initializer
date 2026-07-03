#!/usr/bin/env bash
# ============================================================================
# Master Test Runner — runs all test suites for opencode_initializer
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

PASS=0; FAIL=0; TOTAL=0

run_test() {
  local name="$1" cmd="$2"
  TOTAL=$((TOTAL + 1))
  printf "  %-55s " "$name"
  output=$(eval "$cmd" 2>&1)
  if [ $? -eq 0 ]; then
    echo "PASS"
    PASS=$((PASS + 1))
  else
    echo "FAIL"
    echo "    $output" >&2
    FAIL=$((FAIL + 1))
  fi
}

run_test_file() {
  local name="$1" file="$2"
  TOTAL=$((TOTAL + 1))
  printf "  %-55s " "$name"
  output=$(bash "$file" 2>&1)
  if [ $? -eq 0 ]; then
    echo "PASS"
    PASS=$((PASS + 1))
  else
    echo "FAIL"
    echo "    $output" >&2
    FAIL=$((FAIL + 1))
  fi
}

echo "============================================================"
echo "  OpenCode Initializer Test Suite"
echo "  Project: $PROJECT_DIR"
echo "============================================================"

# ── Syntax Checks ─────────────────────────────────────────────────────────
echo
echo "=== Syntax Tests (bash -n) ==="

for f in "$PROJECT_DIR/setup.sh" "$PROJECT_DIR/dev.sh" "$PROJECT_DIR/src/lib/"*.sh "$PROJECT_DIR/src/modes/"*.sh; do
  [ -f "$f" ] || continue
  run_test "Syntax: $(basename "$f")" "bash -n '$f'"
done

for f in "$SCRIPT_DIR"/unit/*.sh "$SCRIPT_DIR"/integration/*.sh "$SCRIPT_DIR"/e2e/*.sh; do
  [ -f "$f" ] || continue
  run_test "Syntax: tests/$(echo "$f" | sed "s|$SCRIPT_DIR/||")" "bash -n '$f'"
done

# Python syntax checks
for f in "$PROJECT_DIR/scripts/"*.py; do
  [ -f "$f" ] || continue
  run_test "Syntax: $(basename "$f")" "python3 -m py_compile '$f'"
done

# Go syntax checks
if command -v gofmt &>/dev/null; then
  for f in "$PROJECT_DIR/src/cockpit/"*.go; do
    [ -f "$f" ] || continue
    run_test "Go fmt: $(basename "$f")" "gofmt -l '$f' | wc -l | grep -q '^0$'"
  done
fi

# ── Unit Tests ────────────────────────────────────────────────────────────
echo
echo "=== Unit Tests ==="

for f in "$SCRIPT_DIR/unit/"*.sh; do
  [ -f "$f" ] || continue
  run_test_file "$(basename "$f")" "$f"
done

# ── Integration Tests ─────────────────────────────────────────────────────
echo
echo "=== Integration Tests ==="

for f in "$SCRIPT_DIR/integration/"*.sh; do
  [ -f "$f" ] || continue
  run_test_file "$(basename "$f")" "$f"
done

# ── E2E Tests ─────────────────────────────────────────────────────────────
echo
echo "=== End-to-End Tests ==="

for f in "$SCRIPT_DIR/e2e/"*.sh; do
  [ -f "$f" ] || continue
  run_test_file "$(basename "$f")" "$f"
done

# ── Results ───────────────────────────────────────────────────────────────
echo
echo "============================================================"
printf "  Results: %d passed, %d failed, %d total\n" "$PASS" "$FAIL" "$TOTAL"
echo "============================================================"

[ "$FAIL" -eq 0 ] || exit 1
