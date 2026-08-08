#!/usr/bin/env bash
# Quick smoke test for 44-audit.sh
set +e
export HOME=/tmp/vaud48
rm -rf "$HOME" 2>/dev/null || true
mkdir -p "$HOME/.cache/opencode-setup"

D="/home/alexandr-narbaev/Projects/opencode_initializer"

log() { :; }; warn() { :; }; info() { :; }; err() { :; }
section() { :; }; _step_skip() { return 1; }; _step_done() { :; }
_gate() { :; }; _spin_start() { :; }; _spin_stop() { :; }
SCRIPT_VERSION="v3.0.0"

source "$D/src/lib/44-audit.sh" 2>&1

echo "---FUNCTIONS---"
declare -F | grep _audit_

echo "---WRITE---"
_audit_event 'model_call' '{"provider":"test"}'
echo "EXIT: $?"

echo "---COUNT---"
wc -l < "$AUDIT_WAL" 2>/dev/null || echo "no file"

echo "---STATS---"
_audit_stats

echo "DONE"
