#!/usr/bin/env bash
# ============================================================================
# Unit Test for 50-sandcastle.sh — Sandboxed AI Coding Agents (Sandcastle)
# Session: ses_sandcastle_test
# ============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
A="$PROJECT_DIR/src/lib/50-sandcastle.sh"

assert() {
  local d="$1" c="$2"
  if (eval "$c") &>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $d" >&2
  fi
}

echo "=== Testing 50-sandcastle.sh ==="

# ── 1. File existence & syntax ───────────────────────────────────────────
assert "50-sandcastle.sh exists" "[ -f '$A' ]"
assert "50-sandcastle.sh syntax clean" "bash -n '$A'"

# ── 2. Core functions ────────────────────────────────────────────────────
assert "has _install_sandcastle()" "grep -q '_install_sandcastle()' '$A'"
assert "has _configure_sandcastle()" "grep -q '_configure_sandcastle()' '$A'"
assert "has _check_sandcastle()" "grep -q '_check_sandcastle()' '$A'"
assert "has _sandcastle_provider()" "grep -q '_sandcastle_provider()' '$A'"
assert "has _sandcastle_scaffold()" "grep -q '_sandcastle_scaffold()' '$A'"

# ── 3. Step tracking & structure ─────────────────────────────────────────
assert "has step_sandcastle skip check" "grep -q 'step_sandcastle' '$A'"
assert "has _step_done step_sandcastle" "grep -q '_step_done step_sandcastle' '$A'"
assert "has section header" "grep -q 'section.*Sandcastle' '$A'"
assert "has shebang" "head -1 '$A' | grep -q '#!/usr/bin/env bash'"
assert "has set -euo pipefail" "grep -q 'set -euo pipefail' '$A'"

# ── 4. Sandcastle directory variable (default .sandcastle) ───────────────
assert "has SANSCASTLE_DIR default .sandcastle" "grep -q 'SANSCASTLE_DIR.*\.sandcastle' '$A'"

# ── 5. Provider detection (docker / podman / no-sandbox) ─────────────────
assert "detects docker provider" "grep -q 'command -v docker' '$A'"
assert "checks docker info" "grep -q 'docker info' '$A'"
assert "detects podman provider" "grep -q 'command -v podman' '$A'"
assert "has no-sandbox fallback" "grep -q 'no-sandbox' '$A'"

# ── 6. Install logic ─────────────────────────────────────────────────────
assert "references @ai-hero/sandcastle" "grep -q '@ai-hero/sandcastle' '$A'"
assert "npm install --save-dev" "grep -q 'npm install --save-dev @ai-hero/sandcastle' '$A'"
assert "has npx init fallback" "grep -q '@ai-hero/sandcastle init' '$A'"
assert "guards missing Node.js" "grep -q 'Node.js not found' '$A'"
assert "guards missing PROJECT_DIR" "grep -q 'PROJECT_DIR not set' '$A'"

# ── 7. Scaffold contents ─────────────────────────────────────────────────
assert "scaffolds main.ts" "grep -q 'main.ts' '$A'"
assert "scaffolds prompt.md" "grep -q 'prompt.md' '$A'"
assert "main.ts imports run/claudeCode" "grep -q 'claudeCode' '$A'"
assert "main.ts imports docker sandbox" "grep -q 'sandboxes/docker' '$A'"
assert "main.ts imports podman sandbox" "grep -q 'sandboxes/podman' '$A'"
assert "main.ts imports no-sandbox" "grep -q 'sandboxes/no-sandbox' '$A'"

# ── 8. Auth / .env configuration ─────────────────────────────────────────
assert "has .env.example template" "grep -q '.env.example' '$A'"
assert "has CLAUDE_CODE_OAUTH_TOKEN" "grep -q 'CLAUDE_CODE_OAUTH_TOKEN' '$A'"
assert "has ANTHROPIC_API_KEY alt" "grep -q 'ANTHROPIC_API_KEY' '$A'"
assert "never overwrites existing .env" "grep -q 'already present' '$A'"

# ── 9. setup.sh reference ────────────────────────────────────────────────
S="$PROJECT_DIR/setup.sh"
assert "setup.sh references 50-sandcastle.sh" "grep -q '50-sandcastle' '$S'"

# ── 10. Functional test: provider + scaffold + configure (with stubs) ────
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

run_functional() {
  (
    # Stub all framework dependencies
    _step_skip()  { return 1; }
    _step_done()  { return 0; }
    section()     { :; }
    log()         { :; }
    warn()        { :; }
    info()        { :; }
    _spin_start() { :; }
    _spin_stop()  { :; }
    # Force `command -v <tool>` to fail so _install_sandcastle short-circuits
    # (no real npm/network) and _sandcastle_provider falls back to no-sandbox.
    command() { if [ "$1" = "-v" ]; then return 1; fi; builtin command "$@"; }

    export PROJECT_DIR="$1"
    source "$A" >/dev/null 2>&1

    echo "provider=$(_sandcastle_provider)"

    _sandcastle_scaffold
    _configure_sandcastle

    for f in main.ts prompt.md .env .env.example; do
      if [ -f "$PROJECT_DIR/.sandcastle/$f" ]; then echo "$f=yes"; else echo "$f=no"; fi
    done
  )
}
FUNC_OUT=$(run_functional "$TMPDIR")

assert "provider fallback is no-sandbox" "echo '$FUNC_OUT' | grep -q 'provider=no-sandbox'"
assert "scaffold creates main.ts" "echo '$FUNC_OUT' | grep -q 'main.ts=yes'"
assert "scaffold creates prompt.md" "echo '$FUNC_OUT' | grep -q 'prompt.md=yes'"
assert "configure creates .env" "echo '$FUNC_OUT' | grep -q '^\.env=yes'"
assert "configure creates .env.example" "echo '$FUNC_OUT' | grep -q '.env.example=yes'"

# ── 11. Functions defined after sourcing (with stubs) ────────────────────
STUBS='_step_skip() { return 1; }; _step_done() { return 0; }; section() { :; }; log() { :; }; warn() { :; }; info() { :; }; _spin_start() { :; }; _spin_stop() { :; }; command() { if [ "$1" = "-v" ]; then return 1; fi; builtin command "$@"; }; export PROJECT_DIR=/tmp'
assert "_install_sandcastle is a function" "bash -c '$STUBS; source \"$A\" 2>/dev/null; declare -f _install_sandcastle >/dev/null 2>&1'"
assert "_configure_sandcastle is a function" "bash -c '$STUBS; source \"$A\" 2>/dev/null; declare -f _configure_sandcastle >/dev/null 2>&1'"
assert "_check_sandcastle is a function" "bash -c '$STUBS; source \"$A\" 2>/dev/null; declare -f _check_sandcastle >/dev/null 2>&1'"

echo "test_sandcastle: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
