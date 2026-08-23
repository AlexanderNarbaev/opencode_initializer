#!/usr/bin/env bash
# ============================================================================
# Unit tests for scripts/check-doc-counts.sh — the self-sync doc-counts gate.
# T1: bash -n (syntax).  T2: executable bit.  T3: gate exits 0 on a synced tree.
# Deliberately number-agnostic: it asserts the gate RUNS and PASSES, never
# hardcodes unit/provider/LSP counts — those belong to the gate itself.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
GATE="$PROJECT_DIR/scripts/check-doc-counts.sh"

PASS=0; FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

# T1 — syntax
if bash -n "$GATE" 2>/dev/null; then pass "check-doc-counts.sh syntax OK"; else fail "check-doc-counts.sh syntax FAIL"; fi

# T2 — executable bit
if [ -x "$GATE" ]; then pass "check-doc-counts.sh is executable"; else fail "check-doc-counts.sh not executable"; fi

# T3 — gate passes on the current (synced) tree
if bash "$GATE" >/dev/null 2>&1; then pass "check-doc-counts.sh exits 0 (docs synced)"; else fail "check-doc-counts.sh exited non-zero"; fi

echo
echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
