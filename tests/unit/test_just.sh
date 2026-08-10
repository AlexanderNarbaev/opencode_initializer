#!/usr/bin/env bash
# Unit test: 23-just.sh — Just task runner
set -euo pipefail

TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }

P="$(cd "$(dirname "$0")/../.." && pwd)"
J="$P/src/lib/23-just.sh"

echo "=== Testing 23-just.sh ==="

# ── File existence & syntax ──
a "23-just.sh exists" "[ -f '$J' ]"
a "23-just.sh syntax" "bash -n '$J'"

# ── Content checks ──
a "has section header" "grep -q 'section.*Just' '$J'"
a "has just check (command -v)" "grep -q 'command -v just' '$J'"
a "has just_ver variable" "grep -q 'just_ver=' '$J'"
a "has GitHub download URL" "grep -q 'github.com/casey/just/releases' '$J'"
a "has cargo fallback" "grep -q 'cargo install just' '$J'"
a "has default justfile creation" "grep -q 'cat.*justfile' '$J'"
a "has build recipe" "grep -q 'build:' '$J'"
a "has test recipe" "grep -q 'test:' '$J'"
a "has lint recipe" "grep -q 'lint:' '$J'"
a "has clean recipe" "grep -q 'clean:' '$J'"
a "has dev recipe" "grep -q 'dev:' '$J'"
a "has _step_done" "grep -q '_step_done' '$J'"

echo "test_just: $TP passed, $TF failed"
[ "$TF" -eq 0 ] || exit 1
