#!/usr/bin/env bash
# test_ecosystem_integration.sh — test 119-ecosystem-integration.sh module
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0; FAIL=0
assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc" >&2
    FAIL=$((FAIL + 1))
  fi
}

MODULE="$PROJECT_DIR/src/lib/119-ecosystem-integration.sh"

echo "=== Testing 119-ecosystem-integration.sh ==="

# ── File structure ────────────────────────────────────────────────────────
assert "module file exists"                          "[ -f \"$MODULE\" ]"
assert "has correct shebang"                         "head -1 \"$MODULE\" | grep -q '#!/usr/bin/env bash'"
assert "has set -euo pipefail"                       "grep -q 'set -euo pipefail' \"$MODULE\""

# ── Function definitions ──────────────────────────────────────────────────
assert "_install_crewai defined"                     "grep -q '_install_crewai()' \"$MODULE\""
assert "_install_langgraph defined"                  "grep -q '_install_langgraph()' \"$MODULE\""
assert "_install_mcp_servers defined"                "grep -q '_install_mcp_servers()' \"$MODULE\""
assert "_install_lsp_servers defined"                "grep -q '_install_lsp_servers()' \"$MODULE\""
assert "_install_dev_tools defined"                  "grep -q '_install_dev_tools()' \"$MODULE\""

# ── References and artifacts ──────────────────────────────────────────────
assert "references ECOSYSTEM-INTEGRATION-GUIDE"      "grep -q 'ECOSYSTEM-INTEGRATION-GUIDE' \"$MODULE\""
assert "docs/ECOSYSTEM-INTEGRATION-GUIDE.md exists"  "[ -f \"$PROJECT_DIR/docs/ECOSYSTEM-INTEGRATION-GUIDE.md\" ]"
assert "docs/ECOSYSTEM-INTEGRATION-SUMMARY.md exists" "[ -f \"$PROJECT_DIR/docs/ECOSYSTEM-INTEGRATION-SUMMARY.md\" ]"
assert "opencode-comprehensive.toml exists"          "[ -f \"$PROJECT_DIR/opencode-comprehensive.toml\" ]"

# ── Syntax ────────────────────────────────────────────────────────────────
assert "module syntax valid (bash -n)"               "bash -n \"$MODULE\""

echo
echo "=== test_ecosystem_integration.sh: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] || exit 1
