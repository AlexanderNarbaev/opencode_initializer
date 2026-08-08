#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
W="$P/src/lib/99-upstream-sync.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
a "exists" "[ -f $W ]"
a "syntax" "bash -n $W"
a "has upstream" "grep -q upstream $W"
a "has sync" "grep -q sync $W"
a "has version" "grep -q version $W"
a "has submodule/git" "grep -qE 'submodule|git' $W"
echo "test_upstream_sync: $TP passed, $TF failed"
[ "$TF" -eq 0 ] || exit 1
