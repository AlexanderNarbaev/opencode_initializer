#!/usr/bin/env bash
# tests/integration/test_skill_pipeline.sh — Integration test: Skill pipeline
# Tests: 62-skill-registry → 63-skill-manager → 64-skill-security → 65-skill-eval
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/src/lib/helpers.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/62-skill-registry.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/63-skill-manager.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/64-skill-security.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/65-skill-eval.sh" 2>/dev/null || true

TESTS=0 PASSED=0 FAILED=0

assert() {
  local desc="$1" result="$2" expected="$3"
  TESTS=$((TESTS + 1))
  if [ "$result" = "$expected" ]; then
    PASSED=$((PASSED + 1))
    echo "  ✓ $desc"
  else
    FAILED=$((FAILED + 1))
    echo "  ✗ $desc (got: '$result', expected: '$expected')"
  fi
}

section "Integration: Skill Pipeline (62-65)"

# Create test skill
TEST_SKILL_DIR=$(mktemp -d)
mkdir -p "$TEST_SKILL_DIR"
cat > "$TEST_SKILL_DIR/SKILL.md" <<'EOF'
# Test Skill
Description: A test skill for integration testing.
Version: 1.0.0
EOF

# Test 1: Validate skill
_skill_validate "$TEST_SKILL_DIR" 2>/dev/null && validate_result="pass" || validate_result="fail"
assert "Skill validation" "$validate_result" "pass"

# Test 2: Security scan
score=$(_skill_security_score "$TEST_SKILL_DIR")
assert "Security score >= 90" "$([ "$score" -ge 90 ] && echo true || echo false)" "true"

# Test 3: Evaluation
completion=$(_skill_eval_completion "$TEST_SKILL_DIR")
assert "Completion score >= 0" "$([ "$completion" -ge 0 ] && echo true || echo false)" "true"

# Test 4: Quality score
quality=$(_skill_eval_quality "$TEST_SKILL_DIR")
assert "Quality score >= 0" "$([ "$quality" -ge 0 ] && echo true || echo false)" "true"

# Test 5: Documentation score
docs=$(_skill_eval_docs "$TEST_SKILL_DIR")
assert "Docs score > 0" "$([ "$docs" -gt 0 ] && echo true || echo false)" "true"

# Test 6: Overall score
overall=$(_skill_eval_overall "completion:$completion" "quality:$quality" "docs:$docs")
assert "Overall score calculated" "$([ "$overall" -gt 0 ] && echo true || echo false)" "true"

# Cleanup
rm -rf "$TEST_SKILL_DIR"

echo
echo "━━━ Integration Results: $PASSED/$TESTS passed, $FAILED failed ━━━"
[ "$FAILED" -eq 0 ] && exit 0 || exit 1
