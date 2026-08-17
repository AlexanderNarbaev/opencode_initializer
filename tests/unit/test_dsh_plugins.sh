#!/usr/bin/env bash
# ============================================================================
# ISOLATED Unit Test for 49-deepseek-harness.sh cordis.yml plugin starter
# Target: src/lib/49-deepseek-harness.sh (cordis.yml heredoc)
# Session: ses_dsh_plugins_test
#
# Tests:
#   (a) Module file + syntax validity
#   (b) cordis.yml heredoc is present + non-empty
#   (c) Starter plugin stubs (pre-session-check, pii-guard, wal-checkpoint)
#   (d) References upstream config-catalog.md (no invented keys)
#   (e) Functional: _configure_deepseek_harness writes a non-empty cordis.yml
#
# Isolation: grep-based + temp DSH_CONFIG_DIR (no live dsh/network run)
# ============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
A="$PROJECT_DIR/src/lib/49-deepseek-harness.sh"

assert() {
  local d="$1" c="$2"
  if (eval "$c") &>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $d" >&2
  fi
}

echo "=== Testing 49-deepseek-harness.sh cordis.yml plugins ==="

# ── (a) Module file + syntax ───────────────────────────────────────────────
assert "49-deepseek-harness.sh exists" "[ -f '$A' ]"
assert "49-deepseek-harness.sh syntax clean" "bash -n '$A'"

# ── (b) cordis.yml heredoc present ─────────────────────────────────────────
assert "has cordis.yml heredoc" "grep -q 'cordis.yml' '$A'"

# ── (c) Starter plugin stubs present ───────────────────────────────────────
assert "references pre-session-check stub" "grep -q 'pre-session-check' '$A'"
assert "references pii-guard stub" "grep -q 'pii-guard' '$A'"
assert "references wal-checkpoint stub" "grep -q 'wal-checkpoint' '$A'"

# ── (d) References upstream catalog (no invented keys) ─────────────────────
assert "references config-catalog.md" "grep -q 'config-catalog.md' '$A'"
assert "documents do-not-invent-keys" "grep -q 'do NOT invent' '$A'"
assert "documents everything-is-a-plugin" "grep -q 'everything is a plugin' '$A'"

# ── (e) Functional: writes a non-empty cordis.yml ──────────────────────────
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Stub framework deps + force `command` to fail so install short-circuits
# (node/dsh absent), then call _configure_deepseek_harness directly with a
# temp config dir and capture the written file.
STUBS='_step_skip() { return 1; }; _step_done() { return 0; }; section() { :; }; log() { :; }; warn() { :; }; info() { :; }; _progress() { :; }; _spin_start() { :; }; _spin_stop() { :; }; command() { return 1; }'

CONFIG_OUT=$(bash -c "$STUBS; source '$A' 2>/dev/null; export DSH_CONFIG_DIR='$TMPDIR'; _configure_deepseek_harness; cat '$TMPDIR/cordis.yml' 2>/dev/null" 2>/dev/null)

assert "cordis.yml created" "[ -f '$TMPDIR/cordis.yml' ]"
assert "cordis.yml is non-empty" "[ -s '$TMPDIR/cordis.yml' ]"
assert "cordis.yml has pre-session-check" "echo '$CONFIG_OUT' | grep -q 'pre-session-check'"
assert "cordis.yml has pii-guard" "echo '$CONFIG_OUT' | grep -q 'pii-guard'"
assert "cordis.yml has wal-checkpoint" "echo '$CONFIG_OUT' | grep -q 'wal-checkpoint'"
assert "cordis.yml references catalog" "echo '$CONFIG_OUT' | grep -q 'config-catalog.md'"

echo "test_dsh_plugins: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
