#!/usr/bin/env bash
# Unit test: 42-hooks.sh — Lifecycle Hooks Framework
# Tests: module validity, stub generation, hook execution, idempotency,
#        convenience wrappers, error handling, ordering, failure propagation
set -euo pipefail

PASS=0; FAIL=0
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
HOOKS_MODULE="$PROJECT_DIR/src/lib/42-hooks.sh"

echo "=== Testing 42-hooks.sh ==="

# ── Test 1: Module file exists ────────────────────────────────────────────────
if [ -f "$HOOKS_MODULE" ]; then
  echo "PASS: 42-hooks.sh exists"
  PASS=$((PASS+1))
else
  echo "FAIL: 42-hooks.sh not found"
  FAIL=$((FAIL+1))
  exit 1
fi

# ── Test 2: bash -n syntax check ──────────────────────────────────────────────
if bash -n "$HOOKS_MODULE" 2>/dev/null; then
  echo "PASS: 42-hooks.sh syntax OK"
  PASS=$((PASS+1))
else
  echo "FAIL: 42-hooks.sh syntax error"
  FAIL=$((FAIL+1))
fi

# ── Isolated test environment ─────────────────────────────────────────────────
TMPDIR=$(mktemp -d /tmp/test_hooks.XXXXXX)
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT
export HOME="$TMPDIR/home"
mkdir -p "$HOME/.config/opencode"

# ── Helper: run function in isolated subshell ─────────────────────────────────
# Uses eval so shell variables like "$HOOKS_DIR" are expanded inside the subshell
run_hooks_test() {
  (
    export HOME="$TMPDIR/home"
    warn() { echo "[WARN] $*" >&2; }
    log()  { echo "[LOG] $*" >&2; }
    info() { echo "[INFO] $*" >&2; }
    err()  { echo "[ERR] $*" >&2; return 1; }
    section() { :; }
    _step_skip() { return 1; }
    _step_done() { :; }

    source "$HOOKS_MODULE" 2>/dev/null
    eval "$@"
  )
}

# ── Test 3: _hooks_setup_dirs creates all 4 type directories ─────────────────
run_hooks_test _hooks_setup_dirs
for htype in pre-request post-response pre-commit on-error; do
  if [ -d "$HOME/.config/opencode/hooks/$htype" ]; then
    echo "PASS: _hooks_setup_dirs creates $htype/"
    PASS=$((PASS+1))
  else
    echo "FAIL: _hooks_setup_dirs missing $htype/"
    FAIL=$((FAIL+1))
  fi
done

# ── Test 4: _hooks_init creates default stub files with +x ───────────────────
# Clean up first to test fresh init
rm -rf "$HOME/.config/opencode/hooks"
run_hooks_test _hooks_init
for stub in 10-pii-check.sh 20-policy-check.sh 50-audit-log.sh; do
  stub_path="$HOME/.config/opencode/hooks/$stub"
  if [ -f "$stub_path" ] && [ -x "$stub_path" ]; then
    echo "PASS: _hooks_init creates executable $stub"
    PASS=$((PASS+1))
  elif [ -f "$stub_path" ]; then
    echo "FAIL: $stub exists but not executable"
    FAIL=$((FAIL+1))
  else
    echo "FAIL: _hooks_init missing $stub"
    FAIL=$((FAIL+1))
  fi
done

# ── Test 5: _hooks_init is idempotent — doesn't overwrite existing ───────────
echo "# custom hook content" >> "$HOME/.config/opencode/hooks/10-pii-check.sh"
run_hooks_test _hooks_init
if grep -q "custom hook content" "$HOME/.config/opencode/hooks/10-pii-check.sh"; then
  echo "PASS: _hooks_init idempotent (custom content preserved)"
  PASS=$((PASS+1))
else
  echo "FAIL: _hooks_init overwrote existing hook"
  FAIL=$((FAIL+1))
fi

# ── Test 6: _hooks_run with empty hook type → warns + returns 1 ──────────────
OUTPUT=$(run_hooks_test '_hooks_run ""' 2>&1) || true
if echo "$OUTPUT" | grep -q "hook_type required"; then
  echo "PASS: _hooks_run with empty type warns"
  PASS=$((PASS+1))
else
  echo "FAIL: _hooks_run with empty type did not warn (got: $OUTPUT)"
  FAIL=$((FAIL+1))
fi

# ── Test 7: _hooks_run with no hooks in directory → returns 0 ────────────────
run_hooks_test _hooks_setup_dirs
rm -f "$HOME/.config/opencode/hooks/pre-request/"*.sh 2>/dev/null || true
if run_hooks_test '_hooks_run pre-request' 2>/dev/null; then
  echo "PASS: _hooks_run returns 0 when no hooks exist"
  PASS=$((PASS+1))
else
  echo "FAIL: _hooks_run should return 0 when no hooks"
  FAIL=$((FAIL+1))
fi

# ── Test 8: _hooks_run with non-existent hook type dir → returns 0 ───────────
rm -rf "$HOME/.config/opencode/hooks/on-error"
if run_hooks_test '_hooks_run on-error' 2>/dev/null; then
  echo "PASS: _hooks_run handles missing hook type directory"
  PASS=$((PASS+1))
else
  echo "FAIL: _hooks_run should return 0 for missing hook type dir"
  FAIL=$((FAIL+1))
fi

# ── Test 9: _hooks_run executes a passing hook ───────────────────────────────
run_hooks_test _hooks_setup_dirs
cat > "$HOME/.config/opencode/hooks/pre-request/10-test-hook.sh" << 'EOF'
#!/usr/bin/env bash
echo "HOOK_RAN_SUCCESS"
exit 0
EOF
chmod +x "$HOME/.config/opencode/hooks/pre-request/10-test-hook.sh"
HOOK_OUTPUT=$(run_hooks_test '_hooks_run pre-request' 2>&1) || true
if echo "$HOOK_OUTPUT" | grep -q "HOOK_RAN_SUCCESS"; then
  echo "PASS: _hooks_run executes hook successfully"
  PASS=$((PASS+1))
else
  echo "FAIL: _hooks_run did not execute hook (got: $HOOK_OUTPUT)"
  FAIL=$((FAIL+1))
fi

# ── Test 10: _hooks_run warns and returns 1 on hook failure ──────────────────
cat > "$HOME/.config/opencode/hooks/pre-request/10-test-hook.sh" << 'EOF'
#!/usr/bin/env bash
echo "HOOK_REJECT_MESSAGE"
exit 1
EOF
chmod +x "$HOME/.config/opencode/hooks/pre-request/10-test-hook.sh"
HOOK_OUTPUT=$(run_hooks_test '_hooks_run pre-request' 2>&1) || true
if echo "$HOOK_OUTPUT" | grep -q "Hook rejected" && \
   echo "$HOOK_OUTPUT" | grep -q "HOOK_REJECT_MESSAGE"; then
  echo "PASS: _hooks_run warns on hook rejection"
  PASS=$((PASS+1))
else
  echo "FAIL: _hooks_run did not handle rejection (got: $HOOK_OUTPUT)"
  FAIL=$((FAIL+1))
fi

# ── Test 11: Non-executable hooks are skipped with warning ───────────────────
cat > "$HOME/.config/opencode/hooks/pre-request/10-test-hook.sh" << 'EOF'
#!/usr/bin/env bash
echo "SHOULD_NOT_RUN"
exit 0
EOF
chmod -x "$HOME/.config/opencode/hooks/pre-request/10-test-hook.sh"
HOOK_OUTPUT=$(run_hooks_test '_hooks_run pre-request' 2>&1) || true
if echo "$HOOK_OUTPUT" | grep -q "not executable" && \
   ! echo "$HOOK_OUTPUT" | grep -q "SHOULD_NOT_RUN"; then
  echo "PASS: _hooks_run skips non-executable hooks"
  PASS=$((PASS+1))
else
  echo "FAIL: _hooks_run should skip non-executable hooks (got: $HOOK_OUTPUT)"
  FAIL=$((FAIL+1))
fi

# ── Test 12: _hooks_pre_request convenience wrapper works ────────────────────
cat > "$HOME/.config/opencode/hooks/pre-request/10-test-hook.sh" << 'EOF'
#!/usr/bin/env bash
echo "PRE_REQUEST_HOOK"
exit 0
EOF
chmod +x "$HOME/.config/opencode/hooks/pre-request/10-test-hook.sh"
WRAP_OUT=$(run_hooks_test _hooks_pre_request 2>&1)
if echo "$WRAP_OUT" | grep -q "PRE_REQUEST_HOOK"; then
  echo "PASS: _hooks_pre_request wrapper works"
  PASS=$((PASS+1))
else
  echo "FAIL: _hooks_pre_request wrapper (got: $WRAP_OUT)"
  FAIL=$((FAIL+1))
fi

# ── Test 13: _hooks_post_response convenience wrapper works ──────────────────
cat > "$HOME/.config/opencode/hooks/post-response/10-audit-hook.sh" << 'EOF'
#!/usr/bin/env bash
echo "POST_RESPONSE_HOOK"
exit 0
EOF
chmod +x "$HOME/.config/opencode/hooks/post-response/10-audit-hook.sh"
WRAP_OUT=$(run_hooks_test _hooks_post_response 2>&1)
if echo "$WRAP_OUT" | grep -q "POST_RESPONSE_HOOK"; then
  echo "PASS: _hooks_post_response wrapper works"
  PASS=$((PASS+1))
else
  echo "FAIL: _hooks_post_response wrapper (got: $WRAP_OUT)"
  FAIL=$((FAIL+1))
fi

# ── Test 14: _hooks_pre_commit convenience wrapper works ─────────────────────
cat > "$HOME/.config/opencode/hooks/pre-commit/10-lint-hook.sh" << 'EOF'
#!/usr/bin/env bash
echo "PRE_COMMIT_HOOK"
exit 0
EOF
chmod +x "$HOME/.config/opencode/hooks/pre-commit/10-lint-hook.sh"
WRAP_OUT=$(run_hooks_test _hooks_pre_commit 2>&1)
if echo "$WRAP_OUT" | grep -q "PRE_COMMIT_HOOK"; then
  echo "PASS: _hooks_pre_commit wrapper works"
  PASS=$((PASS+1))
else
  echo "FAIL: _hooks_pre_commit wrapper (got: $WRAP_OUT)"
  FAIL=$((FAIL+1))
fi

# ── Test 15: _hooks_on_error convenience wrapper works ───────────────────────
cat > "$HOME/.config/opencode/hooks/on-error/10-notify-hook.sh" << 'EOF'
#!/usr/bin/env bash
echo "ON_ERROR_HOOK"
exit 0
EOF
chmod +x "$HOME/.config/opencode/hooks/on-error/10-notify-hook.sh"
WRAP_OUT=$(run_hooks_test _hooks_on_error 2>&1)
if echo "$WRAP_OUT" | grep -q "ON_ERROR_HOOK"; then
  echo "PASS: _hooks_on_error wrapper works"
  PASS=$((PASS+1))
else
  echo "FAIL: _hooks_on_error wrapper (got: $WRAP_OUT)"
  FAIL=$((FAIL+1))
fi

# ── Test 16: Multiple hooks run in filename order ────────────────────────────
run_hooks_test _hooks_setup_dirs
rm -f "$HOME/.config/opencode/hooks/pre-request/"*.sh 2>/dev/null || true
cat > "$HOME/.config/opencode/hooks/pre-request/05-first.sh" << 'EOF'
#!/usr/bin/env bash
echo "FIRST"
exit 0
EOF
chmod +x "$HOME/.config/opencode/hooks/pre-request/05-first.sh"

cat > "$HOME/.config/opencode/hooks/pre-request/20-last.sh" << 'EOF'
#!/usr/bin/env bash
echo "LAST"
exit 0
EOF
chmod +x "$HOME/.config/opencode/hooks/pre-request/20-last.sh"

HOOK_OUTPUT=$(run_hooks_test '_hooks_run pre-request' 2>&1) || true
FIRST_POS=$(echo "$HOOK_OUTPUT" | grep -n "FIRST" | head -1 | cut -d: -f1)
LAST_POS=$(echo "$HOOK_OUTPUT" | grep -n "LAST" | head -1 | cut -d: -f1)
if [ "${FIRST_POS:-0}" -gt 0 ] && [ "${LAST_POS:-0}" -gt 0 ] && \
   [ "$FIRST_POS" -lt "$LAST_POS" ]; then
  echo "PASS: Multiple hooks execute in filename order (FIRST=$FIRST_POS, LAST=$LAST_POS)"
  PASS=$((PASS+1))
else
  echo "FAIL: Multi-hook ordering (got: $HOOK_OUTPUT)"
  FAIL=$((FAIL+1))
fi

# ── Test 17: First failing hook stops further execution ──────────────────────
cat > "$HOME/.config/opencode/hooks/pre-request/05-first.sh" << 'EOF'
#!/usr/bin/env bash
echo "FAIL_FIRST"
exit 1
EOF
chmod +x "$HOME/.config/opencode/hooks/pre-request/05-first.sh"

HOOK_OUTPUT=$(run_hooks_test '_hooks_run pre-request' 2>&1) || true
if echo "$HOOK_OUTPUT" | grep -q "FAIL_FIRST" && \
   ! echo "$HOOK_OUTPUT" | grep -q "LAST" && \
   echo "$HOOK_OUTPUT" | grep -q "Hook rejected"; then
  echo "PASS: Failing hook stops further execution"
  PASS=$((PASS+1))
else
  echo "FAIL: First-fail should stop chain (got: $HOOK_OUTPUT)"
  FAIL=$((FAIL+1))
fi

# ── Test 18: HOOKS_DIR is set and exported ───────────────────────────────────
HOOKS_DIR_VAL=$(run_hooks_test 'echo "$HOOKS_DIR"')
if echo "$HOOKS_DIR_VAL" | grep -q "hooks"; then
  echo "PASS: HOOKS_DIR exported (value=$HOOKS_DIR_VAL)"
  PASS=$((PASS+1))
else
  echo "FAIL: HOOKS_DIR not exported (got: $HOOKS_DIR_VAL)"
  FAIL=$((FAIL+1))
fi

# ── Test 19: All 4 hook type constants are configured in _hooks_setup_dirs ───
HOOK_TYPES=$(run_hooks_test '_hooks_setup_dirs >/dev/null; ls "$HOOKS_DIR"' 2>&1)
TYPE_COUNT=0
for htype in pre-request post-response pre-commit on-error; do
  if echo "$HOOK_TYPES" | grep -q "$htype"; then
    TYPE_COUNT=$((TYPE_COUNT + 1))
  fi
done
if [ "$TYPE_COUNT" -eq 4 ]; then
  echo "PASS: All 4 hook type directories present ($TYPE_COUNT/4)"
  PASS=$((PASS+1))
else
  echo "FAIL: Only $TYPE_COUNT/4 hook type directories"
  FAIL=$((FAIL+1))
fi

# ── Test 20: Stub templates contain expected content ──────────────────────────
STUB_PII=$(cat "$HOME/.config/opencode/hooks/10-pii-check.sh")
STUB_AUDIT=$(cat "$HOME/.config/opencode/hooks/50-audit-log.sh")
STUB_POLICY=$(cat "$HOME/.config/opencode/hooks/20-policy-check.sh")
PII_OK=0; AUDIT_OK=0; POLICY_OK=0
echo "$STUB_PII" | grep -q "PII" && PII_OK=1
echo "$STUB_AUDIT" | grep -q "audit" && AUDIT_OK=1
echo "$STUB_POLICY" | grep -q "policy" && POLICY_OK=1
if [ "$PII_OK" -eq 1 ] && [ "$AUDIT_OK" -eq 1 ] && [ "$POLICY_OK" -eq 1 ]; then
  echo "PASS: Stub templates contain meaningful content"
  PASS=$((PASS+1))
else
  echo "FAIL: Stub templates missing content (PII=$PII_OK AUDIT=$AUDIT_OK POLICY=$POLICY_OK)"
  FAIL=$((FAIL+1))
fi

echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
