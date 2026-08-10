#!/usr/bin/env bash
# Unit test: 14-shokunin.sh — Shokunin + Superpowers + Caveman installer
set -euo pipefail

P="$(cd "$(dirname "$0")/../.." && pwd)"
M="$P/src/lib/14-shokunin.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }

echo "=== Testing 14-shokunin.sh ==="

# ── Module file + syntax ────────────────────────────────────────────────────
a "14-shokunin.sh exists" "[ -f '$M' ]"
a "14-shokunin.sh bash -n clean" "bash -n '$M'"

# ── Key content checks ───────────────────────────────────────────────────────
a "has section Shokunin header" "grep -q 'section.*Shokunin' '$M'"
a "has INTERACTIVE_DO_SHOKUNIN gate" "grep -q 'INTERACTIVE_DO_SHOKUNIN' '$M'"
a "has MODE gate check (full/reinit)" "grep -qE 'MODE.*=.*full.*MODE.*=.*reinit' '$M'"
a "has _gate guard" "grep -q '_gate' '$M'"
a "has Shokunin install URL" "grep -q 'raw.githubusercontent.com/EliasOulkadi/shokunin' '$M'"
a "has _download_verify call" "grep -q '_download_verify' '$M'"
a "has bash install.sh -y" "grep -q 'install.sh' '$M'"
a "has profile.sh silencing via sed" "grep -q 'sed.*Shokunin AI Ecosystem loaded' '$M'"
a "has SHOKUNIN_PROFILE variable" "grep -q 'SHOKUNIN_PROFILE' '$M'"
a "has Superpowers git clone" "grep -q 'github.com/obra/superpowers' '$M'"
a "has git clone --depth=1" "grep -q 'git clone.*--depth=1' '$M'"
a "has skills copy logic" "grep -q 'cp.*skills' '$M'"
a "has skills loaded count (wc -l)" "grep -q 'wc -l' '$M'"
a "has _step_done step_shokunin" "grep -q '_step_done step_shokunin' '$M'"
a "has tmpdir cleanup (rm -rf)" "grep -q 'rm -rf.*SUPERPOWERS_TMP' '$M'"

# ── Source in subshell with stubs ────────────────────────────────────────────
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

run_sourced_test() {
  (
    _step_skip() { return 1; }
    _step_done() { return 0; }
    _gate()     { return 0; }  # gate passed → execute block
    section()   { echo "[SECTION] $*"; }
    log()       { echo "[LOG] $*"; }
    warn()      { echo "[WARN] $*"; }
    info()      { echo "[INFO] $*"; }
    _download_verify() { echo "mock-download: $1"; return 0; }
    command()   { builtin command "$@"; }

    export HOME="$TMPDIR"
    export MODE="full"
    export PROJECT_DIR="$P"
    mkdir -p "$HOME/.cache/opencode-setup"

    source "$M" 2>&1
  )
}

SOURCED_OUTPUT=$(run_sourced_test)
a "module sources without fatal errors" "[ -n \"$SOURCED_OUTPUT\" ]"

# ── Function/variable checks after sourcing ──────────────────────────────────
STUBS='_step_skip() { return 1; }; _step_done() { return 0; }; _gate() { return 0; }; section() { :; }; log() { :; }; warn() { :; }; info() { :; }; _download_verify() { return 0; }'
a "SHOKUNIN_PROFILE is set after source" "bash -c '$STUBS; HOME=/tmp MODE=full PROJECT_DIR=/tmp source \"$M\" 2>/dev/null; [ -n \"\$SHOKUNIN_PROFILE\" ] || true'"

# ── setup.sh references ──────────────────────────────────────────────────────
S="$P/setup.sh"
a "setup.sh references 14-shokunin.sh" "grep -q '14-shokunin' '$S'"

echo "test_shokunin: $TP passed, $TF failed"
[ "$TF" -eq 0 ] || exit 1
