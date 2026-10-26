#!/usr/bin/env bash
# Integration test: `setup.sh --agentic` / `--agentic-check` wiring.
# Hermetic: only exercises the dry-run/check paths, which never install anything.
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SETUP="$PROJECT_DIR/setup.sh"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Test 1: flags are documented ==="
help_out="$(bash "$SETUP" --help 2>&1)"
case "$help_out" in *"--agentic"*) pass "help lists --agentic" ;; *) fail "help misses --agentic" ;; esac
case "$help_out" in *"--agentic-check"*) pass "help lists --agentic-check" ;; *) fail "help misses --agentic-check" ;; esac

echo
echo "=== Test 2: --agentic --dry-run dispatches to the installer (hermetic) ==="
TMP_HOME="$(mktemp -d)"
out="$(HOME="$TMP_HOME" bash "$SETUP" --agentic --dry-run 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "exits 0" || fail "expected rc=0, got $rc"
case "$out" in *"OpenCode v2 agentic stack"*) pass "prints the agentic section header" ;; *) fail "missing section header" ;; esac
case "$out" in *"dry run"*|*"[plan]"*) pass "runs the installer in dry-run mode" ;; *) fail "installer dry-run not invoked" ;; esac
case "$out" in *"Bootstrap complete"*) fail "fell through to the full bootstrap" ;; *) pass "does not run the full bootstrap" ;; esac
# the dry run must not create a global config in the throwaway HOME
[ ! -f "$TMP_HOME/.config/opencode/opencode.json" ] && pass "wrote no global config" || fail "dry run wrote a global config"
rm -rf "$TMP_HOME"

echo
echo "=== Test 3: --agentic-check reports a verdict without writing ==="
TMP_HOME2="$(mktemp -d)"
out2="$(HOME="$TMP_HOME2" bash "$SETUP" --agentic-check 2>&1)"; rc2=$?
case "$out2" in *"Result"*) pass "prints a result block" ;; *) fail "no result block" ;; esac
# setup.sh always creates its own log under $HOME/.cache; the check must not touch config.
[ ! -f "$TMP_HOME2/.config/opencode/opencode.json" ] && pass "check mode wrote no config" || fail "check mode wrote a config"
[ ! -d "$TMP_HOME2/.bun" ] && pass "check mode installed nothing (no ~/.bun)" || fail "check mode created ~/.bun"
[ "$rc2" -eq 1 ] || [ "$rc2" -eq 0 ] && pass "exits with a verdict code ($rc2)" || fail "unexpected rc=$rc2"
rm -rf "$TMP_HOME2"

echo
echo "=== Test 4: --dry-run alone keeps its historical behaviour ==="
TMP_HOME3="$(mktemp -d)"
out3="$(SKIP_MIRROR_RESOLVE=true HOME="$TMP_HOME3" timeout 120 bash "$SETUP" --dry-run 2>&1)"; rc3=$?
[ "$rc3" -eq 0 ] && pass "--dry-run exits 0" || fail "--dry-run exited $rc3"
case "$out3" in *"Bootstrap complete"*) pass "--dry-run still previews the full plan" ;; *) fail "--dry-run lost the full plan" ;; esac
rm -rf "$TMP_HOME3"

echo
echo "=========================================="
echo "RESULTS: $PASS pass, $FAIL fail"
echo "=========================================="
[ "$FAIL" -eq 0 ] || exit 1
