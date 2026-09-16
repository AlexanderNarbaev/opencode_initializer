#!/usr/bin/env bash
# ============================================================================
# Unit tests for diff-before-write + secret-masking in 18-opencode-json.sh
# Tests: determinism (two runs identical), UNCHANGED skip, DRY_RUN no-write,
#        unified diff emitted, secrets redacted.
set -euo pipefail
export SKIP_MIRROR_RESOLVE=true

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
LIB="$PROJECT_DIR/src/lib/18-opencode-json.sh"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

# Use a unique temp HOME for hermetic runs
TMPHOME="$(mktemp -d /tmp/opencode-diff-test.XXXXXX)"
mkdir -p "$TMPHOME/.config/opencode"
export HOME="$TMPHOME"
export MODE="fix-config"

# Source helpers + 00-core (needed for log/info/section functions used by 18-...)
# shellcheck disable=SC1091
source "$PROJECT_DIR/src/lib/helpers.sh" >/dev/null 2>&1 || true
# shellcheck disable=SC1091
source "$PROJECT_DIR/src/lib/00-core.sh" >/dev/null 2>&1 || true
set +e  # tolerate state-check returns

echo "=== Test 1: structural checks ==="
if [ -f "$LIB" ]; then pass "18-opencode-json.sh exists"; else fail "missing"; exit 1; fi
if bash -n "$LIB"; then pass "bash -n clean"; else fail "bash -n failed"; fi
if shellcheck -S error "$LIB" >/dev/null 2>&1; then pass "shellcheck -S error clean"
else fail "shellcheck -S error found issues"; fi

echo
echo "=== Test 2: determinism (two runs produce byte-identical output) ==="
( source "$LIB" 2>/dev/null ) >/dev/null
cp "$TMPHOME/.config/opencode/opencode.json" "$TMPHOME/run1.json"
( source "$LIB" 2>/dev/null ) >/dev/null
cp "$TMPHOME/.config/opencode/opencode.json" "$TMPHOME/run2.json"
if cmp -s "$TMPHOME/run1.json" "$TMPHOME/run2.json"; then
  pass "two consecutive runs produce byte-identical output"
else
  fail "non-deterministic output between runs"
  diff "$TMPHOME/run1.json" "$TMPHOME/run2.json" | head -5
fi

echo
echo "=== Test 3: UNCHANGED path (no write when content matches) ==="
BEFORE_MTIME=$(stat -c "%Y" "$TMPHOME/.config/opencode/opencode.json")
# Second run should emit UNCHANGED and not write
( source "$LIB" 2>"$TMPHOME/unchanged.stderr" 1>/dev/null )
AFTER_MTIME=$(stat -c "%Y" "$TMPHOME/.config/opencode/opencode.json")
if [ "$BEFORE_MTIME" = "$AFTER_MTIME" ]; then
  pass "UNCHANGED: file mtime unchanged (no write)"
else
  fail "UNCHANGED: file mtime changed (was rewritten)"
fi
if grep -q "UNCHANGED" "$TMPHOME/unchanged.stderr"; then
  pass "UNCHANGED: marker emitted to stderr"
else
  fail "UNCHANGED: marker missing"
fi

echo
echo "=== Test 4: DRY_RUN=1 emits proposed to stdout, no write ==="
# Modify the on-disk file to force a diff (otherwise UNCHANGED short-circuits
# before DRY_RUN is consulted).
printf "outdated content for dry-run test\n" > "$TMPHOME/.config/opencode/opencode.json"
BEFORE_MTIME=$(stat -c "%Y" "$TMPHOME/.config/opencode/opencode.json")
DRY_RUN=1 bash -c "
  source '$PROJECT_DIR/src/lib/helpers.sh' 2>/dev/null
  source '$PROJECT_DIR/src/lib/00-core.sh' 2>/dev/null
  source '$LIB' 2>'$TMPHOME/dry.stderr' 1>'$TMPHOME/dry.stdout'
"
AFTER_MTIME=$(stat -c "%Y" "$TMPHOME/.config/opencode/opencode.json")
if [ "$BEFORE_MTIME" = "$AFTER_MTIME" ]; then
  pass "DRY_RUN: file mtime unchanged"
else
  fail "DRY_RUN: file was rewritten"
fi
if grep -q "DRY-RUN" "$TMPHOME/dry.stderr"; then
  pass "DRY_RUN: DRY-RUN marker emitted to stderr"
else
  fail "DRY_RUN: DRY-RUN marker missing"
fi
if [ -s "$TMPHOME/dry.stdout" ] && grep -q '"model"' "$TMPHOME/dry.stdout"; then
  pass "DRY_RUN: proposed JSON written to stdout"
else
  fail "DRY_RUN: stdout missing proposed JSON"
fi

echo
echo "=== Test 5: diff emitted when content changes ==="
# Modify the on-disk file to force a diff
printf "old content for diff test\n" > "$TMPHOME/.config/opencode/opencode.json"
( source "$LIB" 2>"$TMPHOME/diff.stderr" 1>/dev/null )
if grep -qE "^---|^\+\+\+|^@@" "$TMPHOME/diff.stderr"; then
  pass "DIFF: unified-diff format markers present"
else
  fail "DIFF: missing unified-diff markers"
fi
if grep -q "DIFF detected" "$TMPHOME/diff.stderr"; then
  pass "DIFF: 'DIFF detected' marker emitted"
else
  fail "DIFF: marker missing"
fi

echo
echo "=== Test 6: secret-masking in diff output ==="
# Pre-seed an existing file with secret-like patterns
cat > "$TMPHOME/.config/opencode/opencode.json" <<EOF
{
  "old": {
    "apiKey": "sk-SECRETSECRET1234567890abcd",
    "password": "xai-PASSWORDpassword1234abcd",
    "token": "tp-TOKENtoken1234abcd1234"
  },
  "leaked-env-value": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "github_pat_LEAKED1234567890abcdefghij"
  }
}
EOF
( source "$LIB" 2>"$TMPHOME/secret.stderr" 1>/dev/null )
# Check that no unredacted secrets remain
if grep -qE "(sk-|xai-|tp-|dtn_|ghp_|github_pat_)[A-Za-z0-9_-]{15,}" "$TMPHOME/secret.stderr"; then
  fail "secrets appear unredacted in diff"
  grep -nE "(sk-|xai-|tp-|dtn_|ghp_|github_pat_)[A-Za-z0-9_-]{15,}" "$TMPHOME/secret.stderr" | head -3
else
  pass "no unredacted secrets in diff"
fi
if grep -q "REDACTED:ENV" "$TMPHOME/secret.stderr"; then
  pass "REDACTED:ENV marker present"
else
  fail "REDACTED:ENV marker missing"
fi

echo
echo "=========================================="
echo "RESULTS: $PASS pass, $FAIL fail"
echo "=========================================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1