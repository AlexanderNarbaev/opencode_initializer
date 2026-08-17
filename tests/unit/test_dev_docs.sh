#!/usr/bin/env bash
# ============================================================================
# ISOLATED Unit Test for M5: Automation (pre-session hook + dev docs generator)
# Target: src/lib/42-hooks.sh (pre-session hook) + dev.sh (cmd_docs)
# Session: ses_dev_docs_test
# ============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
HOOKS="$PROJECT_DIR/src/lib/42-hooks.sh"
DEV="$PROJECT_DIR/dev.sh"

assert() {
  local d="$1" c="$2"
  if (eval "$c") >/dev/null 2>&1; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $d" >&2
  fi
}

echo "=== Testing M5 automation (42-hooks.sh + dev docs) ==="

# ── 1. File existence + syntax ────────────────────────────────────────────
assert "42-hooks.sh exists" "[ -f '$HOOKS' ]"
assert "42-hooks.sh syntax clean" "bash -n '$HOOKS'"
assert "dev.sh exists" "[ -f '$DEV' ]"
assert "dev.sh syntax clean" "bash -n '$DEV'"

# ── 2. S5.1.1: pre-session hook wraps pre-session-check.sh ─────────────────
assert "has _hooks_stub_presession" "grep -q '_hooks_stub_presession()' '$HOOKS'"
assert "hook references pre-session-check.sh" "grep -q 'pre-session-check.sh' '$HOOKS'"
assert "hook runs _pre_session" "grep -q '_pre_session' '$HOOKS'"
assert "has _hooks_pre_session runner" "grep -q '_hooks_pre_session()' '$HOOKS'"
assert "exports _hooks_pre_session" "grep -q 'export -f _hooks_pre_session' '$HOOKS'"

# ── 3. S5.2.1: dev docs generator derives module tables ────────────────────
assert "has cmd_docs() function" "grep -q 'cmd_docs()' '$DEV'"
assert "docs dispatcher branch" "grep -qE '^\s+docs\)\s+cmd_docs' '$DEV'"
assert "docs scans src/lib modules" "grep -q 'src/lib' '$DEV'"
assert "docs writes MODULES.md" "grep -q 'MODULES.md' '$DEV'"
assert "docs derives from header comment" "grep -q 'head -20' '$DEV'"

# ── 4. Lifecycle hook framework intact (5 hook types) ─────────────────────
for h in pre-session pre-request post-response pre-commit on-error; do
  assert "hook type '$h' referenced" "grep -q '$h' '$HOOKS'"
done

# ── Report ────────────────────────────────────────────────────────────────
echo "test_dev_docs: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
