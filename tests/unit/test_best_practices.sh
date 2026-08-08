#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
W="$P/src/lib/40-best-practices.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
a "exists" "[ -f $W ]"
a "syntax" "bash -n $W"
a "has humanizer" "grep -q humanizer $W"
a "has mentor" "grep -q mentor $W"
a "has disruptor" "grep -q disruptor $W"
a "has skill/skills" "grep -q skill $W"
echo "test_best_practices: $TP passed, $TF failed"
[ "$TF" -eq 0 ] || exit 1
