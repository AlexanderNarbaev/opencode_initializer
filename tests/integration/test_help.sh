#!/usr/bin/env bash
# ============================================================================
# Integration test: help output
# Verifies --help shows all modes, options, and examples
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
TESTS_PASS=0; TESTS_FAIL=0

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $desc" >&2
  fi
}

echo "=== Integration: help output ==="

HELP_OUTPUT=$(bash "$PROJECT_DIR/setup.sh" --help 2>&1) || true
HELP_EXIT=$?

# ── Help exits 0 ──────────────────────────────────────────────────────
assert "help exit code is 0" "[ '$HELP_EXIT' -eq 0 ]"

# ── Help is non-trivial ───────────────────────────────────────────────
assert "help output is substantial" \
  'test $(echo "'"$HELP_OUTPUT"'" | wc -l) -ge 15'

# ── Help contains all modes ───────────────────────────────────────────
for mode in full reinit new health update upgrade fix-config fix-zshrc interactive ci; do
  assert "help: --$mode" 'echo "'"$HELP_OUTPUT"'" | grep -q "\-\-'"$mode"'"'
done

# ── Help contains key options ─────────────────────────────────────────
assert "help: --api-key"           'echo "'"$HELP_OUTPUT"'" | grep -qi "api.key"'
assert "help: --deepseek-key"      'echo "'"$HELP_OUTPUT"'" | grep -q "\-\-deepseek-key"'
assert "help: --github-token"      'echo "'"$HELP_OUTPUT"'" | grep -q "\-\-github-token"'
assert "help: --git-name"          'echo "'"$HELP_OUTPUT"'" | grep -q "\-\-git-name"'
assert "help: --git-email"         'echo "'"$HELP_OUTPUT"'" | grep -q "\-\-git-email"'
assert "help: --sudo-pass"         'echo "'"$HELP_OUTPUT"'" | grep -q "\-\-sudo-pass"'
assert "help: --project-dir"       'echo "'"$HELP_OUTPUT"'" | grep -q "\-\-project-dir"'
assert "help: --dry-run"           'echo "'"$HELP_OUTPUT"'" | grep -q "\-\-dry-run"'

# ── Help contains provider keys ───────────────────────────────────────
for key in xai-key mimo-key moonshot-key minimax-key gitlab-token google-maps-key fzf-key; do
  assert "help: --$key" 'echo "'"$HELP_OUTPUT"'" | grep -q "\-\-'"$key"'"'
done

# ── Help contains Examples section ────────────────────────────────────
assert "help: examples section" 'echo "'"$HELP_OUTPUT"'" | grep -qi "example"'
assert "help: Usage line"       'echo "'"$HELP_OUTPUT"'" | grep -q "Usage"'

echo
echo "=== test_help.sh: $TESTS_PASS passed, $TESTS_FAIL failed ==="
[ "$TESTS_FAIL" -eq 0 ] || exit 1
