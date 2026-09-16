#!/usr/bin/env bash
# tests/unit/test_security_benchmark.sh — Tests for security and benchmark (v4.2.0/v4.3.0)
set -euo pipefail
export SKIP_MIRROR_RESOLVE=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

_green() { echo -e "\033[0;32m$1\033[0m"; }
_red()   { echo -e "\033[0;31m$1\033[0m"; }

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  if [ "$expected" = "$actual" ]; then
    _green "  ✓ $desc"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ $desc — expected '$expected', got '$actual'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_true() {
  local desc="$1" result="$2"
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  if [ "$result" = "0" ]; then
    _green "  ✓ $desc"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ $desc — expected success, got $result"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_file_exists() {
  local desc="$1" file="$2"
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  if [ -f "$file" ]; then
    _green "  ✓ $desc"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ $desc — file not found: $file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_contains() {
  local desc="$1" file="$2" pattern="$3"
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  if grep -q "$pattern" "$file" 2>/dev/null; then
    _green "  ✓ $desc"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ $desc — pattern not found: $pattern"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "=== test_security_benchmark.sh ==="

# ── Test 1: Module files exist ──────────────────────────────────────────────
echo "Test 1: Module file structure"
assert_file_exists "00k-security-scan.sh exists" "$SCRIPT_DIR/src/lib/00k-security-scan.sh"
assert_file_exists "00l-benchmark.sh exists" "$SCRIPT_DIR/src/lib/00l-benchmark.sh"

# ── Test 2: Security functions defined ──────────────────────────────────────
echo "Test 2: Security functions"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00k-security-scan.sh"

  assert_true "_scan_secrets defined" "$(type -t _scan_secrets &>/dev/null && echo 0 || echo 1)"
  assert_true "_verify_integrity defined" "$(type -t _verify_integrity &>/dev/null && echo 0 || echo 1)"
  assert_true "_audit_permissions defined" "$(type -t _audit_permissions &>/dev/null && echo 0 || echo 1)"
  assert_true "_scan_dependencies defined" "$(type -t _scan_dependencies &>/dev/null && echo 0 || echo 1)"
  assert_true "_generate_security_report defined" "$(type -t _generate_security_report &>/dev/null && echo 0 || echo 1)"
  assert_true "_install_pre_commit_hook defined" "$(type -t _install_pre_commit_hook &>/dev/null && echo 0 || echo 1)"
)

# ── Test 3: Benchmark functions defined ─────────────────────────────────────
echo "Test 3: Benchmark functions"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00l-benchmark.sh"

  assert_true "_benchmark_start defined" "$(type -t _benchmark_start &>/dev/null && echo 0 || echo 1)"
  assert_true "_benchmark_stop defined" "$(type -t _benchmark_stop &>/dev/null && echo 0 || echo 1)"
  assert_true "_benchmark_cmd defined" "$(type -t _benchmark_cmd &>/dev/null && echo 0 || echo 1)"
  assert_true "_benchmark_network defined" "$(type -t _benchmark_network &>/dev/null && echo 0 || echo 1)"
  assert_true "_benchmark_disk defined" "$(type -t _benchmark_disk &>/dev/null && echo 0 || echo 1)"
  assert_true "_benchmark_cpu defined" "$(type -t _benchmark_cpu &>/dev/null && echo 0 || echo 1)"
  assert_true "_benchmark_memory defined" "$(type -t _benchmark_memory &>/dev/null && echo 0 || echo 1)"
  assert_true "_run_benchmark defined" "$(type -t _run_benchmark &>/dev/null && echo 0 || echo 1)"
)

# ── Test 4: Secret scanning ─────────────────────────────────────────────────
echo "Test 4: Secret scanning"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00k-security-scan.sh"

  # Create test file with fake secret
  tmp_dir=$(mktemp -d)
  echo 'OPENAI_API_KEY="sk-1234567890abcdefghijklmnopqrstuvwxyz1234567890"' > "$tmp_dir/test.sh"

  # Scan should find the secret
  result=$(_scan_secrets "$tmp_dir")
  assert_eq "Secret found" "1" "$result"

  rm -rf "$tmp_dir"
)

# ── Test 5: Integrity verification ──────────────────────────────────────────
echo "Test 5: Integrity verification"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00k-security-scan.sh"

  # Create test file
  tmp_file=$(mktemp)
  echo "test content" > "$tmp_file"

  # Get hash
  expected_hash=$(sha256sum "$tmp_file" | awk '{print $1}')

  # Verify should pass
  result=0
  _verify_integrity "$tmp_file" "$expected_hash" || result=$?
  assert_eq "Integrity check passes" "0" "$result"

  # Verify with wrong hash should fail
  result=0
  _verify_integrity "$tmp_file" "wrong_hash" || result=$?
  assert_eq "Integrity check fails on mismatch" "1" "$result"

  rm -f "$tmp_file"
)

# ── Test 6: Permission audit ────────────────────────────────────────────────
echo "Test 6: Permission audit"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00k-security-scan.sh"

  # Create test directory
  tmp_dir=$(mktemp -d)
  touch "$tmp_dir/normal_file.sh"
  chmod 755 "$tmp_dir/normal_file.sh"

  # Audit should pass
  result=$(_audit_permissions "$tmp_dir")
  assert_eq "No permission issues" "0" "$result"

  rm -rf "$tmp_dir"
)

# ── Test 7: Benchmark timer ─────────────────────────────────────────────────
echo "Test 7: Benchmark timer"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00l-benchmark.sh"

  # Test timer
  _benchmark_start "test_op"
  sleep 0.1
  duration=$(_benchmark_stop "test_op")

  # Duration should be >= 100ms
  if [ "$duration" -ge 100 ]; then
    _green "  ✓ Timer works (${duration}ms)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ Timer too fast (${duration}ms)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
)

# ── Test 8: Benchmark command ───────────────────────────────────────────────
echo "Test 8: Benchmark command"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00l-benchmark.sh"

  # Benchmark a simple command
  duration=$(_benchmark_cmd "echo_test" sleep 0.1)

  # Duration should be >= 100ms
  if [ "$duration" -ge 100 ]; then
    _green "  ✓ Command benchmark works (${duration}ms)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ Command benchmark too fast (${duration}ms)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
)

# ── Test 9: Security report generation ──────────────────────────────────────
echo "Test 9: Security report"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00k-security-scan.sh"

  # Use temp directory
  export DL_CACHE=$(mktemp -d)
  _SECURITY_REPORT="$DL_CACHE/security-report.json"

  # Create clean test directory
  tmp_dir=$(mktemp -d)
  echo "# Clean file" > "$tmp_dir/clean.sh"

  # Generate report
  _generate_security_report "$tmp_dir" 2>/dev/null || true

  assert_file_exists "Report created" "$_SECURITY_REPORT"

  # Verify JSON is valid
  if python3 -c "import json; json.load(open('$_SECURITY_REPORT'))" 2>/dev/null; then
    _green "  ✓ Report is valid JSON"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ Report is not valid JSON"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_TOTAL=$((TESTS_TOTAL + 1))

  rm -rf "$DL_CACHE" "$tmp_dir"
)

# ── Test 10: Pre-commit hook ────────────────────────────────────────────────
echo "Test 10: Pre-commit hook"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00k-security-scan.sh"

  # Create temp git directory
  tmp_dir=$(mktemp -d)
  mkdir -p "$tmp_dir/.git/hooks"

  _install_pre_commit_hook "$tmp_dir/.git"

  assert_file_exists "Hook created" "$tmp_dir/.git/hooks/pre-commit"
  assert_contains "Hook has secret patterns" "$tmp_dir/.git/hooks/pre-commit" "sk-\[a-zA-Z0-9\]"

  rm -rf "$tmp_dir"
)

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "=== Summary ==="
echo "Total:  $TESTS_TOTAL"
_green "Passed: $TESTS_PASSED"
if [ "$TESTS_FAILED" -gt 0 ]; then
  _red "Failed: $TESTS_FAILED"
  exit 1
else
  echo "Failed: 0"
  exit 0
fi
