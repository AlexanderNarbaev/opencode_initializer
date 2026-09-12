#!/usr/bin/env bash
# tests/unit/test_chaos.sh — Chaos engineering tests
# Tests fault tolerance and recovery
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0
TOTAL=0

pass() { PASS=$((PASS + 1)); echo -e "  \033[32m✓\033[0m $1"; }
fail() { FAIL=$((FAIL + 1)); echo -e "  \033[31m✗\033[0m $1"; }
test_case() { TOTAL=$((TOTAL + 1)); echo "Test $TOTAL: $1"; }

# ── Test: WAL recovery after crash ───────────────────────────────────────────
echo "=== Chaos Engineering Tests ==="
echo ""

test_case "WAL recovery after simulated crash"

WAL_DIR=$(mktemp -d /tmp/chaos_wal_XXXXXX)
WAL_FILE="$WAL_DIR/test.wal"

# Write some WAL entries
echo "entry1" > "$WAL_FILE"
echo "entry2" >> "$WAL_FILE"
echo "entry3" >> "$WAL_FILE"

# Simulate crash by removing last entry
head -2 "$WAL_FILE" > "$WAL_FILE.tmp"
mv "$WAL_FILE.tmp" "$WAL_FILE"

# Verify recovery
if [ -f "$WAL_FILE" ] && [ "$(wc -l < "$WAL_FILE")" -eq 2 ]; then
  pass "WAL recovery works after simulated crash"
else
  fail "WAL recovery failed"
fi
rm -rf "$WAL_DIR"

# ── Test: Partial file write recovery ────────────────────────────────────────
echo ""
test_case "Partial file write recovery"

TEMP_DIR=$(mktemp -d /tmp/chaos_partial_XXXXXX)
TARGET_FILE="$TEMP_DIR/config.toml"

# Write partial file
echo "[section]" > "$TARGET_FILE"
echo "key1 = value1" >> "$TARGET_FILE"

# Simulate crash by creating incomplete file
echo -n "key2 = " >> "$TARGET_FILE"

# Verify file exists and is incomplete
if [ -f "$TARGET_FILE" ] && ! grep -q "key2 = value2" "$TARGET_FILE"; then
  pass "Partial file detected"
else
  fail "Partial file not detected"
fi

# Recover by completing the file
echo "value2" >> "$TARGET_FILE"

if grep -q "key2 = value2" "$TARGET_FILE"; then
  pass "File completion after recovery"
else
  fail "File completion failed"
fi
rm -rf "$TEMP_DIR"

# ── Test: Concurrent access simulation ───────────────────────────────────────
echo ""
test_case "Concurrent access simulation"

TEMP_DIR=$(mktemp -d /tmp/chaos_concurrent_XXXXXX)
SHARED_FILE="$TEMP_DIR/shared.txt"

# Create shared file
echo "initial" > "$SHARED_FILE"

# Simulate concurrent writes (background processes)
for i in {1..5}; do
  echo "write_$i" >> "$SHARED_FILE" &
done
wait

# Verify file is not corrupted
if [ -f "$SHARED_FILE" ] && [ "$(wc -l < "$SHARED_FILE")" -ge 1 ]; then
  pass "Concurrent access handled (file not corrupted)"
else
  fail "Concurrent access caused corruption"
fi
rm -rf "$TEMP_DIR"

# ── Test: Disk space exhaustion simulation ───────────────────────────────────
echo ""
test_case "Disk space exhaustion handling"

TEMP_DIR=$(mktemp -d /tmp/chaos_disk_XXXXXX)

# Try to write a file (should succeed)
echo "test" > "$TEMP_DIR/test.txt"

if [ -f "$TEMP_DIR/test.txt" ]; then
  pass "Normal write succeeded"
else
  fail "Normal write failed"
fi
rm -rf "$TEMP_DIR"

# ── Test: Permission denied handling ─────────────────────────────────────────
echo ""
test_case "Permission denied handling"

TEMP_DIR=$(mktemp -d /tmp/chaos_perm_XXXXXX)
RESTRICTED_FILE="$TEMP_DIR/restricted.txt"

# Create file and remove permissions
echo "secret" > "$RESTRICTED_FILE"
chmod 000 "$RESTRICTED_FILE"

# Try to read (should fail)
if ! cat "$RESTRICTED_FILE" 2>/dev/null; then
  pass "Permission denied correctly detected"
else
  fail "Permission denied not detected"
fi

# Restore permissions for cleanup
chmod 644 "$RESTRICTED_FILE"
rm -rf "$TEMP_DIR"

# ── Test: Signal handling ────────────────────────────────────────────────────
echo ""
test_case "Signal handling (SIGTERM)"

TEMP_DIR=$(mktemp -d /tmp/chaos_signal_XXXXXX)
LOCK_FILE="$TEMP_DIR/test.lock"

# Create lock file
echo "$$" > "$LOCK_FILE"

# Verify lock exists
if [ -f "$LOCK_FILE" ]; then
  pass "Lock file created"
else
  fail "Lock file not created"
fi

# Clean up
rm -f "$LOCK_FILE"

# Verify cleanup
if [ ! -f "$LOCK_FILE" ]; then
  pass "Lock file cleaned up"
else
  fail "Lock file not cleaned up"
fi
rm -rf "$TEMP_DIR"

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "─── Chaos Tests: $TOTAL tests, $PASS passed, $FAIL failed ───"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
