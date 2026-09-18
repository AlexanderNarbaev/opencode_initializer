#!/usr/bin/env bash
# tests/unit/test_parallel_engine.sh — Tests for parallel installation engine (v3.5.0)
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

echo "=== test_parallel_engine.sh ==="

# ── Test 1: Module file exists ──────────────────────────────────────────────
echo "Test 1: Module file structure"
assert_file_exists "00d-parallel.sh exists" "$SCRIPT_DIR/src/lib/00d-parallel.sh"
assert_file_exists "00e-cache-mgr.sh exists" "$SCRIPT_DIR/src/lib/00e-cache-mgr.sh"
assert_file_exists "00f-apm.sh exists" "$SCRIPT_DIR/src/lib/00f-apm.sh"

# ── Test 2: Parallel functions defined ──────────────────────────────────────
echo "Test 2: Function definitions"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00d-parallel.sh"

  assert_true "_parallel_run_layer defined" "$(type -t _parallel_run_layer &>/dev/null && echo 0 || echo 1)"
  assert_true "_parallel_wait_all defined" "$(type -t _parallel_wait_all &>/dev/null && echo 0 || echo 1)"
  assert_true "_parallel_install defined" "$(type -t _parallel_install &>/dev/null && echo 0 || echo 1)"
  assert_true "_process_skip_flags defined" "$(type -t _process_skip_flags &>/dev/null && echo 0 || echo 1)"
  assert_true "_should_install defined" "$(type -t _should_install &>/dev/null && echo 0 || echo 1)"
  assert_true "_mark_installed defined" "$(type -t _mark_installed &>/dev/null && echo 0 || echo 1)"
)

# ── Test 3: Skip flags processing ───────────────────────────────────────────
echo "Test 3: Skip flags"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00d-parallel.sh"

  # Test single skip flag
  _process_skip_flags "devbox"
  assert_eq "SKIP_DEVBOX set" "true" "${SKIP_DEVBOX:-false}"

  # Test multiple skip flags
  _process_skip_flags "gui,cockpit,caching"
  assert_eq "SKIP_GUI set" "true" "${SKIP_GUI:-false}"
  assert_eq "SKIP_COCKPIT set" "true" "${SKIP_COCKPIT:-false}"
  assert_eq "SKIP_CACHING set" "true" "${SKIP_CACHING:-false}"
)

# ── Test 4: Incremental install markers ─────────────────────────────────────
echo "Test 4: Incremental install"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00d-parallel.sh"

  # Test marker creation
  _mark_installed "test-module"
  assert_file_exists "Marker created" "${DL_CACHE}/installed/test-module"

  # Test should_install returns 1 for recent marker
  result=0
  _should_install "test-module" || result=$?
  assert_eq "Skip recent install" "1" "$result"

  # Test force reinstall
  FORCE_REINSTALL=true
  result=1
  _should_install "test-module" && result=$?
  assert_eq "Force reinstall" "0" "$result"

  # Cleanup
  rm -f "${DL_CACHE}/installed/test-module"
)

# ── Test 5: Parallel execution with mock modules ────────────────────────────
echo "Test 5: Parallel execution"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00d-parallel.sh"

  # Create mock module files
  tmp_dir=$(mktemp -d)
  cat > "$tmp_dir/mod1.sh" <<'EOF'
echo "mod1 running"
sleep 0.1
return 0
EOF
  cat > "$tmp_dir/mod2.sh" <<'EOF'
echo "mod2 running"
sleep 0.1
return 0
EOF
  cat > "$tmp_dir/mod3.sh" <<'EOF'
echo "mod3 running"
return 1
EOF

  # Test parallel layer with success
  result=0
  _parallel_run_layer "test" \
    "step_mod1:$tmp_dir/mod1.sh:Module 1" \
    "step_mod2:$tmp_dir/mod2.sh:Module 2" || result=$?
  assert_eq "Parallel layer success" "0" "$result"

  # Cleanup
  rm -rf "$tmp_dir"
)

# ── Test 6: Cache manager functions ─────────────────────────────────────────
echo "Test 6: Cache manager"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00e-cache-mgr.sh"

  # Test cache key generation
  key1=$(_cache_key "https://example.com/file1.tar.gz")
  key2=$(_cache_key "https://example.com/file2.tar.gz")
  if [ "$key1" != "$key2" ]; then
    assert_true "Cache keys different" "echo 0"
  else
    assert_true "Cache keys different" "echo 1"
  fi

  # Test cache initialization
  _cache_init
  assert_file_exists "Cache index created" "${_CACHE_ROOT}/.cache-index.json"

  # Test cache miss
  result=0
  _cache_hit "https://nonexistent.example.com/file.tar.gz" || result=$?
  assert_eq "Cache miss" "1" "$result"
)

# ── Test 7: APM generation ──────────────────────────────────────────────────
echo "Test 7: APM generation"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00f-apm.sh"

  tmp_apm=$(mktemp)

  # Test minimal APM generation
  _apm_generate_minimal "$tmp_apm"
  assert_file_exists "APM file created" "$tmp_apm"

  # Verify APM content
  if grep -q "schema_version:" "$tmp_apm" && \
     grep -q "opencode-initializer" "$tmp_apm" && \
     grep -q "dependencies:" "$tmp_apm"; then
    _green "  ✓ APM content valid"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ APM content invalid"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_TOTAL=$((TESTS_TOTAL + 1))

  # Cleanup
  rm -f "$tmp_apm"
)

# ── Test 8: APM from TOML ───────────────────────────────────────────────────
echo "Test 8: APM from TOML"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00f-apm.sh"

  # Check if TOML template exists
  toml_template="$SCRIPT_DIR/src/data/setup.toml.template"
  if [ -f "$toml_template" ]; then
    tmp_apm=$(mktemp)

    _apm_generate "$toml_template" "$tmp_apm"
    assert_file_exists "APM from TOML created" "$tmp_apm"

    # Verify content
    if grep -q "dependencies:" "$tmp_apm" && \
       grep -q "features:" "$tmp_apm" && \
       grep -q "services:" "$tmp_apm"; then
      _green "  ✓ APM from TOML valid"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      _red "  ✗ APM from TOML invalid"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    rm -f "$tmp_apm"
  else
    echo "  ⚠ TOML template not found — skipping"
  fi
)

# ── Test 9: SBOM export ─────────────────────────────────────────────────────
echo "Test 9: SBOM export"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00f-apm.sh"

  # Create test APM file
  tmp_apm=$(mktemp)
  tmp_sbom=$(mktemp)

  _apm_generate_minimal "$tmp_apm"
  _apm_export_sbom "$tmp_apm" "$tmp_sbom"

  assert_file_exists "SBOM created" "$tmp_sbom"

  # Verify SBOM is valid JSON
  if python3 -c "import json; json.load(open('$tmp_sbom'))" 2>/dev/null; then
    _green "  ✓ SBOM is valid JSON"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ SBOM is not valid JSON"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_TOTAL=$((TESTS_TOTAL + 1))

  # Cleanup
  rm -f "$tmp_apm" "$tmp_sbom"
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
