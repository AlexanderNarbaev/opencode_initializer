#!/usr/bin/env bash
# test_grace_semantics.sh — test 56-grace-semantics.sh module
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0; FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

MODULE="$PROJECT_DIR/src/lib/56-grace-semantics.sh"
[ -f "$MODULE" ] && pass "56-grace-semantics.sh exists" || { fail "missing"; exit 1; }
bash -n "$MODULE" 2>/dev/null && pass "56-grace-semantics.sh syntax OK" || fail "syntax FAIL"

# Test the six functions exist
grep -q '_grace_contract_emit' "$MODULE" && pass "_grace_contract_emit defined" || fail "missing"
grep -q '_grace_clarity_score' "$MODULE" && pass "_grace_clarity_score defined" || fail "missing"
grep -q '_grace_position' "$MODULE" && pass "_grace_position defined" || fail "missing"
grep -q '_grace_sparse_focus' "$MODULE" && pass "_grace_sparse_focus defined" || fail "missing"
grep -q '_grace_normalize' "$MODULE" && pass "_grace_normalize defined" || fail "missing"
grep -q '_grace_hallucination_check' "$MODULE" && pass "_grace_hallucination_check defined" || fail "missing"

# Isolated temp dir: the module's default Main targets README.md, so run the
# runtime checks here to avoid polluting the repo root with *.grace.yaml.
TDIR="$(mktemp -d)"
TARGET="$TDIR/test.sh"
printf '# test\n' > "$TARGET"
printf 'This is a test prompt with acceptance criteria and must verify\n' > "$TDIR/prompt.txt"

# Repo convention: define helper stubs BEFORE sourcing the module.
STUBS='warn(){ :;}; log(){ :;}; info(){ :;}; ok(){ :;}; section(){ :;}; _step_skip(){ return 1; }; _step_done(){ :; };'

# Test contract emit creates a sidecar file
(
  cd "$TDIR" || exit 1
  HOME="$TDIR"; export HOME
  eval "$STUBS"
  source "$MODULE" 2>/dev/null || true
  _grace_contract_emit "$TARGET"
)
[ -f "$TARGET.grace.yaml" ] && pass "contract emit creates sidecar file" || fail "contract emit FAIL"

# Test clarity score runs without error (capture output first — avoids the
# grep -q early-exit SIGPIPE race in a pipefail pipeline).
CLARITY_OUT="$(
  cd "$TDIR" || exit 1
  HOME="$TDIR"; export HOME
  eval "$STUBS"
  source "$MODULE" 2>/dev/null || true
  _grace_clarity_score "$TDIR/prompt.txt"
)"
printf '%s\n' "$CLARITY_OUT" | grep -q "clarity:" && pass "clarity score runs" || fail "clarity score FAIL"

# Cleanup
rm -rf "$TDIR"

echo
echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
