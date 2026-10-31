#!/usr/bin/env bash
# Unit tests for scripts/dsh-setup.sh — hermetic: temp HOME, stubbed dsh binary.
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$PROJECT_DIR/scripts/dsh-setup.sh"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAKE_HOME="$TMP/home"
mkdir -p "$FAKE_HOME/.config/opencode/skills/demo"
printf -- '---\nname: demo\ndescription: demo skill\n---\n' > "$FAKE_HOME/.config/opencode/skills/demo/SKILL.md"

mkdir -p "$TMP/bin"
cat > "$TMP/bin/dsh" <<'STUB'
#!/usr/bin/env bash
case "${1:-}" in
  --version) echo "0.2.1-rc.2" ;;
  --profile) exit 0 ;;
esac
exit 0
STUB
chmod +x "$TMP/bin/dsh"

export HOME="$FAKE_HOME"
export DSH_HOME="$FAKE_HOME/.dsh"
export PATH="$TMP/bin:$PATH"

echo "=== Test 1: script is present and parses ==="
[ -f "$SCRIPT" ] && pass "scripts/dsh-setup.sh exists" || fail "dsh-setup.sh missing"
bash -n "$SCRIPT" 2>/dev/null && pass "syntax" || fail "syntax"
[ -f "$PROJECT_DIR/src/data/dsh/cordis.patch.web.yml" ] && pass "profile template exists" || fail "profile template missing"
[ -f "$PROJECT_DIR/src/data/dsh/AGENTS.md" ] && pass "AGENTS template exists" || fail "AGENTS template missing"

echo
echo "=== Test 2: --apply provisions a fresh DSH home ==="
out="$(bash "$SCRIPT" --apply 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "--apply exits 0" || fail "--apply exited $rc: $out"
[ -f "$DSH_HOME/profiles/web/cordis.patch.yml" ] && pass "profile patch written" || fail "profile patch missing"
[ -f "$DSH_HOME/AGENTS.md" ] && pass "user AGENTS.md written" || fail "user AGENTS.md missing"
[ -L "$DSH_HOME/skills" ] && pass "skills symlink created" || fail "skills symlink missing"
[ -d "$DSH_HOME/mcp" ] && pass "memory dir created" || fail "memory dir missing"

echo
echo "=== Test 3: rendered placeholders and routes ==="
patch_file="$DSH_HOME/profiles/web/cordis.patch.yml"
grep -q "MEMORY_FILE_PATH: $HOME/.dsh/mcp/memory.json" "$patch_file" \
  && pass "__HOME__ rendered in memory path" || fail "memory path not rendered"
grep -q 'model: deepseek-v4-pro' "$patch_file" && pass "default model deepseek-v4-pro" || fail "default model missing"
grep -q 'mcp-context7' "$patch_file" && pass "context7 MCP entry present" || fail "context7 entry missing"
grep -q 'mcp-memory' "$patch_file" && pass "memory MCP entry present" || fail "memory entry missing"
grep -q '__HOME__' "$DSH_HOME/AGENTS.md" && fail "AGENTS.md still contains placeholder" || pass "AGENTS.md rendered"

echo
echo "=== Test 4: --check passes after apply ==="
bash "$SCRIPT" --check >/dev/null 2>&1 && pass "--check exits 0" || fail "--check failed after apply"

echo
echo "=== Test 5: drift is backed up and repaired ==="
echo '# manual drift' >> "$patch_file"
out="$(bash "$SCRIPT" --apply 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "re-apply exits 0" || fail "re-apply exited $rc"
ls "$DSH_HOME/profiles/web"/cordis.patch.yml.bak.* >/dev/null 2>&1 \
  && pass "backup created for drifted file" || fail "no backup created"
grep -q 'manual drift' "$patch_file" && fail "drift not repaired" || pass "drift repaired"

echo
echo "=== Test 6: --dry-run changes nothing ==="
DRY_HOME="$TMP/dry"
DSH_HOME="$DRY_HOME" bash "$SCRIPT" --dry-run >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "--dry-run exits 0" || fail "--dry-run exited $rc"
[ -e "$DRY_HOME/profiles/web/cordis.patch.yml" ] && fail "--dry-run wrote the patch" || pass "--dry-run wrote nothing"
[ -e "$DRY_HOME/AGENTS.md" ] && fail "--dry-run wrote AGENTS.md" || pass "--dry-run did not write AGENTS.md"

echo
echo "=== Test 7: --check fails on a missing profile ==="
DSH_HOME="$TMP/empty" bash "$SCRIPT" --check >/dev/null 2>&1; rc=$?
[ "$rc" -ne 0 ] && pass "--check fails when profile absent" || fail "--check passed with no profile"

echo
echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
