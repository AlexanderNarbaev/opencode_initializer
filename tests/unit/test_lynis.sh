#!/usr/bin/env bash
# Unit test: 47-lynis.sh — Lynis security audit scanner + weekly cron
set -euo pipefail

P="$(cd "$(dirname "$0")/../.." && pwd)"
M="$P/src/lib/47-lynis.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }

echo "=== Testing 47-lynis.sh ==="

# ── Module file + syntax ────────────────────────────────────────────────
a "47-lynis.sh exists" "[ -f '$M' ]"
a "47-lynis.sh bash -n clean" "bash -n '$M'"

# ── Key content checks ───────────────────────────────────────────────────
a "has _lynis_install function" "grep -q '_lynis_install()' '$M'"
a "has _lynis_audit function" "grep -q '_lynis_audit()' '$M'"
a "has _lynis_setup_cron function" "grep -q '_lynis_setup_cron()' '$M'"
a "has cisofy GPG key URL" "grep -q 'packages.cisofy.com/keys' '$M'"
a "has cisofy apt repo" "grep -q 'cisofy-lynis.list' '$M'"
a "has GPG dearmor command" "grep -q 'gpg --dearmor' '$M'"
a "has apt-get install lynis" "grep -q 'apt-get install.*lynis' '$M'"
a "has hardening index >=80 check" "grep -q 'Hardening index' '$M'"
a "has hardening target >=80" "grep -qE 'ge 80' '$M'"
a "has cron.weekly path" "grep -q 'cron.weekly' '$M'"
a "has lynis-audit cron file" "grep -q 'lynis-audit' '$M'"
a "has step_lynis gate" "grep -q 'step_lynis' '$M'"
a "has section output" "grep -q 'section.*Lynis' '$M'"
a "has --cronjob flag" "grep -q 'cronjob' '$M'"

# ── Source in subshell with stubs ────────────────────────────────────────
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

run_sourced_test() {
  (
    # Stub all dependencies
    _step_skip() { return 1; }
    _step_done() { return 0; }
    section()   { echo "[SECTION] $*"; }
    log()       { echo "[LOG] $*"; }
    warn()      { echo "[WARN] $*"; }
    info()      { echo "[INFO] $*"; }
    _spin_start() { :; }
    _spin_stop()  { :; }
    _curl()     { echo "mock-curl: $*"; }
    command()   { [ "$1" = "-v" ] && shift; if [ "$1" = "lynis" ]; then return 1; fi; builtin command "$@"; }
    sudo()      { echo "mock-sudo: $*"; }
    apt-get()   { echo "mock-apt: $*"; }
    tee()       { cat >/dev/null; }

    export HOME="$TMPDIR"
    mkdir -p "$HOME/.cache/opencode-setup"

    source "$M" 2>&1
  )
}

# Run the sourced test and capture output
SOURCED_OUTPUT=$(run_sourced_test)
a "module sources without fatal errors" "[ -n \"$SOURCED_OUTPUT\" ]"

# Verify functions are defined after sourcing (with stubs)
STUBS='_step_skip() { return 1; }; _step_done() { return 0; }; section() { :; }; log() { :; }; warn() { :; }; info() { :; }; _spin_start() { :; }; _spin_stop() { :; }; _curl() { :; }; command() { builtin command "$@"; }'
a "_lynis_install is a function" "bash -c '$STUBS; source \"$M\" 2>/dev/null; declare -f _lynis_install >/dev/null 2>&1'"
a "_lynis_audit is a function" "bash -c '$STUBS; source \"$M\" 2>/dev/null; declare -f _lynis_audit >/dev/null 2>&1'"
a "_lynis_setup_cron is a function" "bash -c '$STUBS; source \"$M\" 2>/dev/null; declare -f _lynis_setup_cron >/dev/null 2>&1'"

# ── setup.sh references ──────────────────────────────────────────────────
S="$P/setup.sh"
a "setup.sh references 47-lynis.sh" "grep -q '47-lynis' '$S'"

echo "test_lynis: $TP passed, $TF failed"
[ "$TF" -eq 0 ] || exit 1
