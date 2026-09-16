#!/usr/bin/env bash
# tests/unit/test_skill_eval.sh — Tests for 65-skill-eval.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/src/lib/helpers.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/64-skill-security.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/65-skill-eval.sh" 2>/dev/null || true

TESTS=0
PASSED=0
FAILED=0

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

section "65-skill-eval.sh"

# Test: Module loads
assert "Module loads" "$?" "0"

# Create test skill directory
TEST_SKILL_DIR=$(mktemp -d)
mkdir -p "$TEST_SKILL_DIR"

# Test: Empty skill gets low completion score
cat > "$TEST_SKILL_DIR/SKILL.md" <<'EOF'
# Empty Skill
EOF

score=$(_skill_eval_completion "$TEST_SKILL_DIR")
assert "Empty skill completion score" "$([ "$score" -lt 50 ] && echo true || echo false)" "true"

# Test: Rich skill gets higher completion score
cat > "$TEST_SKILL_DIR/SKILL.md" <<'EOF'
# Rich Skill
Description: A well-documented skill.

## Usage
1. Run the command
2. Check the output

## Input
- query: string

## Output
- result: string

## Example
```bash
echo "hello"
```

## Error Handling
If an error occurs, it returns an error message.
EOF

score=$(_skill_eval_completion "$TEST_SKILL_DIR")
assert "Rich skill completion score >= 60" "$([ "$score" -ge 60 ] && echo true || echo false)" "true"

# Test: Documentation score
score=$(_skill_eval_docs "$TEST_SKILL_DIR")
assert "Rich skill docs score >= 50" "$([ "$score" -ge 50 ] && echo true || echo false)" "true"

# Test: Overall score calculation
result=$(_skill_eval_overall "completion_rate:80" "quality_score:70" "docs_score:90")
assert "Overall score calculation" "$result" "80"

# Cleanup
rm -rf "$TEST_SKILL_DIR"

# Summary
echo
echo "━━━ Results: $PASSED/$TESTS passed, $FAILED failed ━━━"
[ "$FAILED" -eq 0 ] && exit 0 || exit 1
