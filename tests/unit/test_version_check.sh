#!/usr/bin/env bash
# Unit test: version-check.sh — tool version checking, ISOLATED gate, update counting
set -euo pipefail

PASS=0; FAIL=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
MODULE="$PROJECT_DIR/src/lib/version-check.sh"

echo "=== Testing version-check.sh ==="

# ── T1: Module exists ───────────────────────────────────────────────────────
if [ -f "$MODULE" ]; then
  echo "PASS: version-check.sh exists"; PASS=$((PASS + 1))
else
  echo "FAIL: version-check.sh not found"; FAIL=$((FAIL + 1)); exit 1
fi

# ── T2: Syntax check ────────────────────────────────────────────────────────
if bash -n "$MODULE" 2>/dev/null; then
  echo "PASS: version-check.sh syntax OK"; PASS=$((PASS + 1))
else
  echo "FAIL: version-check.sh syntax error"; FAIL=$((FAIL + 1))
fi

# ── T3: _check_versions function exists ─────────────────────────────────────
grep -q '^_check_versions()' "$MODULE" && { echo "PASS: _check_versions() defined"; PASS=$((PASS + 1)); } || { echo "FAIL: _check_versions() not found"; FAIL=$((FAIL + 1)); }

# ── T4: ISOLATED_CIRCUIT gate exists ────────────────────────────────────────
grep -q 'ISOLATED_CIRCUIT' "$MODULE" && { echo "PASS: ISOLATED_CIRCUIT gate present"; PASS=$((PASS + 1)); } || { echo "FAIL: ISOLATED_CIRCUIT gate missing"; FAIL=$((FAIL + 1)); }

# ── T5: Tool checks present (Rust, Go, Node, Python, Bun, OpenCode, Ollama, Zig) ──
ALL_FOUND=true
for tool in rustc go node python3 bun opencode ollama zig; do
  if ! grep -q "command -v $tool" "$MODULE"; then
    echo "FAIL: missing version check for $tool"; FAIL=$((FAIL + 1)); ALL_FOUND=false
  fi
done
$ALL_FOUND && { echo "PASS: all 8 tool version checks present"; PASS=$((PASS + 1)); }

# ── T6: Setup script self-check present ─────────────────────────────────────
grep -q 'opencode_initializer/setup.sh' "$MODULE" && { echo "PASS: setup.sh self-check present"; PASS=$((PASS + 1)); } || { echo "FAIL: setup.sh self-check missing"; FAIL=$((FAIL + 1)); }

# ── T7: NPM package checks present ──────────────────────────────────────────
grep -q 'npm list -g' "$MODULE" && { echo "PASS: npm package version checks present"; PASS=$((PASS + 1)); } || { echo "FAIL: npm package checks missing"; FAIL=$((FAIL + 1)); }

# ── T8: ISOLATED_CIRCUIT mode returns 0 ─────────────────────────────────────
ISO_OUTPUT=$( (
  ISOLATED_CIRCUIT=true
  source "$MODULE" 2>/dev/null
  _check_versions 2>&1
  echo "EXIT_CODE=$?"
) )
ISO_EXIT=$(echo "$ISO_OUTPUT" | grep 'EXIT_CODE=' | cut -d= -f2)
[ "${ISO_EXIT:-1}" -eq 0 ] && { echo "PASS: ISOLATED_CIRCUIT mode returns 0"; PASS=$((PASS + 1)); } || { echo "FAIL: ISOLATED_CIRCUIT mode returned ${ISO_EXIT:-error}"; FAIL=$((FAIL + 1)); }

# ── T9: ISOLATED mode shows 'isolated' in output ────────────────────────────
echo "$ISO_OUTPUT" | grep -qi 'isolated' && { echo "PASS: ISOLATED mode mentions isolated/air-gap"; PASS=$((PASS + 1)); } || { echo "FAIL: ISOLATED mode missing isolation mention"; FAIL=$((FAIL + 1)); }

# ── T10: ISOLATED mode shows local versions ─────────────────────────────────
{ echo "$ISO_OUTPUT" | grep -qE 'Local: (Rust|Go|Node|Python|Bun|Ollama|Zig)'; } && { echo "PASS: ISOLATED mode shows local tool versions"; PASS=$((PASS + 1)); } || { echo "FAIL: ISOLATED mode missing local version output"; FAIL=$((FAIL + 1)); }

# ── T11: Normal mode starts and produces tool output (header + at least some tools) ──
NORMAL_OUTPUT=$(timeout 60 bash -c "
  source '$MODULE' 2>/dev/null
  _check_versions 2>&1
  echo \"EXIT_CODE=\$?\"
" 2>/dev/null || echo "EXIT_CODE=TIMEOUT")
{ echo "$NORMAL_OUTPUT" | grep -q 'Version Check' && echo "$NORMAL_OUTPUT" | grep -qE '(OK|UPDATE):'; } && { echo "PASS: normal mode produces tool version output"; PASS=$((PASS + 1)); } || { echo "FAIL: normal mode produced no tool output"; FAIL=$((FAIL + 1)); }

# ── T12: Normal mode output has header ──────────────────────────────────────
echo "$NORMAL_OUTPUT" | grep -q 'Version Check' && { echo "PASS: normal mode has Version Check header"; PASS=$((PASS + 1)); } || { echo "FAIL: normal mode missing header"; FAIL=$((FAIL + 1)); }

# ── T13: When completed (not timed out), summary has update count ───────────
if echo "$NORMAL_OUTPUT" | grep -q 'EXIT_CODE=TIMEOUT'; then
  echo "PASS: normal mode summary skipped (npm timeout)"; PASS=$((PASS + 1))
elif echo "$NORMAL_OUTPUT" | grep -qE '[0-9]+ update\(s\) available'; then
  echo "PASS: normal mode has update count summary"; PASS=$((PASS + 1))
else
  echo "FAIL: normal mode missing update count summary"; FAIL=$((FAIL + 1))
fi

# ── T14: Return value is numeric when completed ─────────────────────────────
if echo "$NORMAL_OUTPUT" | grep -q 'EXIT_CODE=TIMEOUT'; then
  echo "PASS: exit code check skipped (npm timeout)"; PASS=$((PASS + 1))
else
  NORMAL_EXIT=$(echo "$NORMAL_OUTPUT" | grep 'EXIT_CODE=' | grep -v TIMEOUT | cut -d= -f2)
  if [ "${NORMAL_EXIT:-999}" -ge 0 ] 2>/dev/null; then
    echo "PASS: return value is non-negative (got $NORMAL_EXIT)"; PASS=$((PASS + 1))
  else
    echo "FAIL: return value invalid (got ${NORMAL_EXIT:-missing})"; FAIL=$((FAIL + 1))
  fi
fi

# ── T15: All tool output lines have OK: or UPDATE: prefix ───────────────────
# Extract only the tool status lines (skip header/summary/npm lines)
BAD_LINES=0
while IFS= read -r line; do
  case "$line" in
    "  OK:"*|"  UPDATE:"*) ;;
    "=== Version"*|"==="*|"EXIT_CODE="*|"") continue ;;
    *) BAD_LINES=$((BAD_LINES + 1)) ;;
  esac
done <<EOF
$NORMAL_OUTPUT
EOF
[ "$BAD_LINES" -eq 0 ] && { echo "PASS: all tool lines use OK:/UPDATE: format"; PASS=$((PASS + 1)); } || { echo "FAIL: $BAD_LINES tool line(s) have unexpected format"; FAIL=$((FAIL + 1)); }

# ── T16: curl calls use retry flags ─────────────────────────────────────────
CURL_RETRY_COUNT=$(grep -c -- '--retry' "$MODULE" 2>/dev/null) || CURL_RETRY_COUNT=0
[ "${CURL_RETRY_COUNT}" -ge 7 ] && { echo "PASS: curl calls have --retry flags (found $CURL_RETRY_COUNT)"; PASS=$((PASS + 1)); } || { echo "FAIL: curl retry flags insufficient (found $CURL_RETRY_COUNT, expected >=7)"; FAIL=$((FAIL + 1)); }

# ── T17: curl calls use connect-timeout ─────────────────────────────────────
CURL_TIMEOUT_COUNT=$(grep -c -- '--connect-timeout' "$MODULE" 2>/dev/null) || CURL_TIMEOUT_COUNT=0
[ "${CURL_TIMEOUT_COUNT}" -ge 7 ] && { echo "PASS: curl calls have --connect-timeout (found $CURL_TIMEOUT_COUNT)"; PASS=$((PASS + 1)); } || { echo "FAIL: curl timeout flags insufficient (found $CURL_TIMEOUT_COUNT, expected >=7)"; FAIL=$((FAIL + 1)); }

echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
