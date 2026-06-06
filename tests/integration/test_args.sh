#!/usr/bin/env bash
# ============================================================================
# Integration test: argument parsing
# Validates all CLI modes, options, and aliases exist in source code.
# Does NOT invoke setup.sh (would trigger slow _mirror_url network calls).
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

echo "=== Integration: argument parsing ==="

SETUP="$PROJECT_DIR/setup.sh"

# ── All CLI modes exist in case statement ──────────────────────────────
for mode in full reinit health update upgrade interactive new fix-config fix-zshrc dry-run; do
  assert "mode $mode in source" 'grep -q "\-\-'"$mode"'" "'"$SETUP"'"'
done

# ── MODE assignment for each flag ──────────────────────────────────────
for mode in full reinit health update upgrade interactive new fix-config fix-zshrc dry-run; do
  assert "MODE=$mode assigned in source" 'grep -q "MODE=.*'"$mode"'" "'"$SETUP"'"'
done

# ── All CLI options exist in source ────────────────────────────────────
for opt in api-key deepseek-key xai-key mimo-key moonshot-key minimax-key github-token gitlab-token google-maps-key fzf-key git-name git-email sudo-pass project-dir dry-run; do
  assert "option --$opt in source" 'grep -q "\-\-'"$opt"'" "'"$SETUP"'"'
done

# ── Short aliases exist ────────────────────────────────────────────────
assert "short -p|--project-dir" 'grep -q "\-p|" "'"$SETUP"'"'
assert "short -k|--api-key"     'grep -q "\-k|" "'"$SETUP"'"'
assert "short -n|--git-name"    'grep -q "\-n|" "'"$SETUP"'"'
assert "short -e|--git-email"   'grep -q "\-e|" "'"$SETUP"'"'
assert "short -s|--sudo-pass"   'grep -q "\-s|" "'"$SETUP"'"'
assert "short -h|--help"        'grep -q "\-h|" "'"$SETUP"'"'

# ── Help heredoc contains mode descriptions ────────────────────────────
assert "help describes --full"           'grep -q "Complete bootstrap" "'"$SETUP"'"'
assert "help describes --reinit"         'grep -q "Reinstall tools" "'"$SETUP"'"'
assert "help describes --health"         'grep -q "Diagnostic" "'"$SETUP"'"'
assert "help describes --update"         'grep -q "Update tools" "'"$SETUP"'"'
assert "help describes --interactive"    'grep -q "Interactive" "'"$SETUP"'"'
assert "help describes --fix-zshrc"      'grep -q "Repair" "'"$SETUP"'"'

# ── Help heredoc contains examples ─────────────────────────────────────
assert "help has examples" 'grep -qi "example" "'"$SETUP"'"'

# ── setup.sh syntax is valid ───────────────────────────────────────────
bash -n "$SETUP" 2>/dev/null
assert "setup.sh passes bash -n" "[ $? -eq 0 ]"

# ── Total argument count ───────────────────────────────────────────────
ARG_COUNT=$(grep -c 'shift' "$SETUP" 2>/dev/null || echo 0)
assert "setup.sh has shift statements" "[ '$ARG_COUNT' -ge 5 ]"

echo
echo "=== test_args.sh: $TESTS_PASS passed, $TESTS_FAIL failed ==="
[ "$TESTS_FAIL" -eq 0 ] || exit 1
