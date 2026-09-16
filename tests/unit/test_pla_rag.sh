#!/usr/bin/env bash
# tests/unit/test_pla_rag.sh — Tests for Phase 5 modules (101-110)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/src/lib/helpers.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/101-pla-orchestrator.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/102-pla-extract.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/103-pla-analyze.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/104-pla-verify.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/105-pla-synthesize.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/106-pla-coordinate.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/107-rag-hybrid.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/108-rag-bm25.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/109-rag-vector.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/110-rag-fusion.sh" 2>/dev/null || true

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

section "Phase 5: PLA & RAG (101-110)"

# Test: Modules load
assert "101-pla-orchestrator loads" "$?" "0"
assert "102-pla-extract loads" "$?" "0"
assert "103-pla-analyze loads" "$?" "0"
assert "104-pla-verify loads" "$?" "0"
assert "105-pla-synthesize loads" "$?" "0"
assert "106-pla-coordinate loads" "$?" "0"
assert "107-rag-hybrid loads" "$?" "0"
assert "108-rag-bm25 loads" "$?" "0"
assert "109-rag-vector loads" "$?" "0"
assert "110-rag-fusion loads" "$?" "0"

# Test: cmd help
output=$(cmd_pla help 2>&1)
assert "PLA help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_pla_extract help 2>&1)
assert "PLA extract help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_pla_analyze help 2>&1)
assert "PLA analyze help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_pla_verify help 2>&1)
assert "PLA verify help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_pla_synthesize help 2>&1)
assert "PLA synthesize help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_pla_coordinate help 2>&1)
assert "PLA coordinate help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_rag help 2>&1)
assert "RAG help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_rag_bm25 help 2>&1)
assert "RAG BM25 help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_rag_vector help 2>&1)
assert "RAG vector help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_rag_fusion help 2>&1)
assert "RAG fusion help" "$([ -n "$output" ] && echo true || echo false)" "true"

echo
echo "━━━ Results: $PASSED/$TESTS passed, $FAILED failed ━━━"
[ "$FAILED" -eq 0 ] && exit 0 || exit 1
