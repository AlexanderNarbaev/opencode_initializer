# Unit Test Record — check-doc-counts.sh

- **Session:** ses_check_doc_counts
- **Target:** `scripts/check-doc-counts.sh`
- **Result:** 8 passed, 0 failed
- **Date:** 2026-08-23

## Summary

Doc-drift gate (harness-engineering lesson from prior waves: docs diverged to
"13 LSP" / "23 providers" while code ground truth was 12 LSP / 22 providers).
Script counts ground truth from code (find tests/{unit,integration,e2e} for
.sh/.py; jq providers/lsp) and asserts the canonical doc strings match.

Verified hermetically (sandbox mirror, no repo mutation):
- syntax (`bash -n`), harness-engineering header comment present
- OK path: exit 0 + `doc-counts: OK (unit=2 intg=1 e2e=1 providers=3 lsp=4)`
- drift unit count → exit 1 + `COUNT MISMATCH: README.md`
- anti-pattern `13 LSP` in README.ru.md → exit 1
- anti-pattern `23 AI provider` in docs/index.en.md → exit 1
- drift integration count in docs/index.ru.md → exit 1

Also: `bash -n` clean, `shellcheck -S error` clean, live run →
`doc-counts: OK (unit=81 intg=6 e2e=5 providers=22 lsp=12)`, exit 0.

## Deleted test code

```bash
#!/usr/bin/env bash
# ISOLATED Unit Test for scripts/check-doc-counts.sh — hermetic sandbox (no repo mutation)
set -euo pipefail

PASS=0; FAIL=0
REPO="/home/alexandr-narbaev/Projects/opencode_initializer"
SRC="$REPO/scripts/check-doc-counts.sh"

ok()   { echo "PASS: $1"; PASS=$((PASS+1)); }
bad()  { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

[ -f "$SRC" ] && ok "script exists" || { bad "script missing"; exit 1; }
bash -n "$SRC" 2>/dev/null && ok "bash -n syntax" || bad "syntax error"
grep -q 'check-doc-counts.sh — fail when docs drift from code ground truth (harness-engineering gate)' "$SRC" \
  && ok "harness-engineering header present" || bad "header missing"

TMP="$(mktemp -d /tmp/check-doc-counts-test.XXXXXX)"
mkdir -p "$TMP/proj/scripts" "$TMP/proj/tests/unit" "$TMP/proj/tests/integration" \
         "$TMP/proj/tests/e2e" "$TMP/proj/src/data" "$TMP/proj/docs"
cp "$SRC" "$TMP/proj/scripts/check-doc-counts.sh"
chmod +x "$TMP/proj/scripts/check-doc-counts.sh"

touch "$TMP/proj/tests/unit/a.sh" "$TMP/proj/tests/unit/b.py"
touch "$TMP/proj/tests/integration/c.sh" "$TMP/proj/tests/e2e/d.sh"
printf '{"providers":[1,2,3]}' > "$TMP/proj/src/data/providers.json"
printf '{"lsp":[1,2,3,4]}' > "$TMP/proj/opencode.json"
printf 't/  # Unit (2), integration (1), E2E (1)\n' > "$TMP/proj/README.md"
printf '... unit/ (2 files), integration/ (1), e2e/ (1)\n' > "$TMP/proj/AGENTS.md"
printf '| Test suite | 9 checks (2 unit + 1 integration + 1 e2e) |\n' > "$TMP/proj/docs/index.en.md"
printf '| tests | 9 (2 unit + 1 integration + 1 e2e) |\n' > "$TMP/proj/docs/index.ru.md"
printf 't/  # Unit (2)\n' > "$TMP/proj/README.ru.md"

run_gate() {
  if OUT=$(bash "$TMP/proj/scripts/check-doc-counts.sh" 2>&1); then RC=0; else RC=$?; fi
}

run_gate
{ [ "$RC" -eq 0 ] && echo "$OUT" | grep -q 'doc-counts: OK (unit=2 intg=1 e2e=1 providers=3 lsp=4)'; } \
  && ok "OK path" || bad "OK path failed: rc=$RC out=$OUT"

printf 't/  # Unit (3), integration (1), E2E (1)\n' > "$TMP/proj/README.md"
run_gate
{ [ "$RC" -eq 1 ] && echo "$OUT" | grep -q 'COUNT MISMATCH: README.md'; } \
  && ok "drift unit caught" || bad "drift not caught: rc=$RC out=$OUT"
printf 't/  # Unit (2), integration (1), E2E (1)\n' > "$TMP/proj/README.md"

printf 't/  # Unit (2), 13 LSP servers\n' > "$TMP/proj/README.ru.md"
run_gate
{ [ "$RC" -eq 1 ] && echo "$OUT" | grep -q '13 LSP'; } \
  && ok "anti-pattern 13 LSP caught" || bad "13 LSP not caught"
printf 't/  # Unit (2)\n' > "$TMP/proj/README.ru.md"

printf '| Test suite | 9 checks (2 unit + 1 integration + 1 e2e) |\n23 AI providers\n' > "$TMP/proj/docs/index.en.md"
run_gate
{ [ "$RC" -eq 1 ] && echo "$OUT" | grep -q '23 AI provider'; } \
  && ok "anti-pattern 23 AI provider caught" || bad "23 AI provider not caught"

printf '| tests | 9 (2 unit + 5 integration + 1 e2e) |\n' > "$TMP/proj/docs/index.ru.md"
run_gate
{ [ "$RC" -eq 1 ] && echo "$OUT" | grep -q 'COUNT MISMATCH: docs/index.ru.md'; } \
  && ok "docs/index.ru.md drift caught" || bad "index.ru drift not caught"

echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
```
