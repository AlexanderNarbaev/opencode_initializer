#!/usr/bin/env bash
# check-doc-counts.sh — fail when docs drift from code ground truth (harness-engineering gate)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

FAIL=0
mismatch() {
  echo "COUNT MISMATCH: $1 (hint: update counts after adding tests/providers/LSPs)" >&2
  FAIL=$((FAIL + 1))
}

# ── Ground truth straight from the code ───────────────────────────────────
UNIT=$(find tests/unit -maxdepth 1 \( -name '*.sh' -o -name '*.py' \) | wc -l | tr -d ' ')
INTG=$(find tests/integration -maxdepth 1 \( -name '*.sh' -o -name '*.py' \) | wc -l | tr -d ' ')
E2E=$(find tests/e2e -maxdepth 1 \( -name '*.sh' -o -name '*.py' \) | wc -l | tr -d ' ')
PROVIDERS=$(jq '.providers | length' src/data/providers.json)
LSP=$(jq '.lsp | length' opencode.json)

# ── Canonical doc places must match the ground truth ──────────────────────
grep -q "Unit (${UNIT})" README.md        || mismatch "README.md: expected 'Unit (${UNIT})'"
grep -q "Unit (${UNIT})" README.ru.md     || mismatch "README.ru.md: expected 'Unit (${UNIT})'"
grep -q "unit/ (${UNIT} files)" AGENTS.md || mismatch "AGENTS.md: expected 'unit/ (${UNIT} files)'"
grep -q "(${UNIT} unit + ${INTG} integration + ${E2E} e2e)" docs/index.en.md || mismatch "docs/index.en.md: expected '(${UNIT} unit + ${INTG} integration + ${E2E} e2e)'"
grep -q "(${UNIT} unit + ${INTG} integration + ${E2E} e2e)" docs/index.ru.md || mismatch "docs/index.ru.md: expected '(${UNIT} unit + ${INTG} integration + ${E2E} e2e)'"
grep -Eq "${PROVIDERS} (AI |LLM )?providers" README.md AGENTS.md || mismatch "providers claim"
grep -Eq "${LSP} LSP" README.md AGENTS.md docs/index.en.md       || mismatch "lsp claim"

# ── Stale anti-patterns must never reappear ───────────────────────────────
for pat in "13 LSP" "23 LLM" "23 provider" "23 AI provider"; do
  if grep -qF -- "$pat" README.md README.ru.md AGENTS.md docs/index.en.md docs/index.ru.md; then
    mismatch "stale count '$pat' still present"
  fi
done

if [ "$FAIL" -ne 0 ]; then
  echo "doc-counts: FAIL ($FAIL mismatches)" >&2
  exit 1
fi

echo "doc-counts: OK (unit=$UNIT intg=$INTG e2e=$E2E providers=$PROVIDERS lsp=$LSP)"
