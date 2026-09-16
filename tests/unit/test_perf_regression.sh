#!/usr/bin/env bash
# tests/unit/test_perf_regression.sh — Performance regression tests
# Tests that critical operations don't regress in performance
set -uo pipefail
export SKIP_MIRROR_RESOLVE=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0
TOTAL=0

pass() { PASS=$((PASS + 1)); echo -e "  \033[32m✓\033[0m $1"; }
fail() { FAIL=$((FAIL + 1)); echo -e "  \033[31m✗\033[0m $1"; }
test_case() { TOTAL=$((TOTAL + 1)); echo "Test $TOTAL: $1"; }

# Performance thresholds (milliseconds)
MAX_CORE_LOAD_TIME=3000
MAX_TOML_PARSE_TIME=500
MAX_HELP_DISPLAY_TIME=200

# ── Test: Core module load time ──────────────────────────────────────────────
echo "=== Performance Regression Tests ==="
echo ""

test_case "Core module load time < ${MAX_CORE_LOAD_TIME}ms"

START_TIME=$(date +%s%N)
source "$PROJECT_ROOT/src/lib/helpers.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/00-core.sh" 2>/dev/null || true
END_TIME=$(date +%s%N)

DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))

if [ "$DURATION_MS" -lt "$MAX_CORE_LOAD_TIME" ]; then
  pass "Core loaded in ${DURATION_MS}ms (threshold: ${MAX_CORE_LOAD_TIME}ms)"
else
  fail "Core loaded in ${DURATION_MS}ms (threshold: ${MAX_CORE_LOAD_TIME}ms)"
fi

# ── Test: TOML parsing time ─────────────────────────────────────────────────
echo ""
test_case "TOML parsing time < ${MAX_TOML_PARSE_TIME}ms"

TEMP_TOML=$(mktemp /tmp/perf_XXXXXX.toml)
cat > "$TEMP_TOML" << 'EOF'
[meta]
version = "1.0"

[user]
name = "Test User"
email = "test@example.com"

[features]
docker = true
postgres = "17"
nodejs = "24"

[services]
postgres = true
redis = true
qdrant = true
EOF

START_TIME=$(date +%s%N)
python3 -c "import tomllib; tomllib.load(open('$TEMP_TOML', 'rb'))" 2>/dev/null
END_TIME=$(date +%s%N)

DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))

if [ "$DURATION_MS" -lt "$MAX_TOML_PARSE_TIME" ]; then
  pass "TOML parsed in ${DURATION_MS}ms (threshold: ${MAX_TOML_PARSE_TIME}ms)"
else
  fail "TOML parsed in ${DURATION_MS}ms (threshold: ${MAX_TOML_PARSE_TIME}ms)"
fi
rm -f "$TEMP_TOML"

# ── Test: Help display time ─────────────────────────────────────────────────
echo ""
test_case "Help display time < ${MAX_HELP_DISPLAY_TIME}ms"

START_TIME=$(date +%s%N)
bash "$PROJECT_ROOT/setup.sh" --help >/dev/null 2>&1
END_TIME=$(date +%s%N)

DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))

if [ "$DURATION_MS" -lt "$MAX_HELP_DISPLAY_TIME" ]; then
  pass "Help displayed in ${DURATION_MS}ms (threshold: ${MAX_HELP_DISPLAY_TIME}ms)"
else
  fail "Help displayed in ${DURATION_MS}ms (threshold: ${MAX_HELP_DISPLAY_TIME}ms)"
fi

# ── Test: Test suite execution time ─────────────────────────────────────────
echo ""
test_case "Core test suite < 30s"

START_TIME=$(date +%s%N)
timeout 30 bash "$PROJECT_ROOT/tests/unit/test_core.sh" >/dev/null 2>&1
TEST_EXIT=$?
END_TIME=$(date +%s%N)

DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))

if [ "$TEST_EXIT" -eq 0 ] && [ "$DURATION_MS" -lt 30000 ]; then
  pass "Core tests completed in ${DURATION_MS}ms"
else
  fail "Core tests failed or took too long: ${DURATION_MS}ms"
fi

# ── Test: File I/O performance ──────────────────────────────────────────────
echo ""
test_case "File I/O performance (1000 writes < 1s)"

TEMP_DIR=$(mktemp -d /tmp/perf_io_XXXXXX)

START_TIME=$(date +%s%N)
for i in {1..1000}; do
  echo "test_$i" > "$TEMP_DIR/file_$i.txt"
done
END_TIME=$(date +%s%N)

DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))

if [ "$DURATION_MS" -lt 1000 ]; then
  pass "1000 file writes in ${DURATION_MS}ms"
else
  fail "1000 file writes took ${DURATION_MS}ms (threshold: 1000ms)"
fi
rm -rf "$TEMP_DIR"

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "─── Performance Tests: $TOTAL tests, $PASS passed, $FAIL failed ───"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
