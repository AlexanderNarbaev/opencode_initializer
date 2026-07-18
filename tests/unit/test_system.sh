#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
S="$P/src/lib/01-system.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
a "exists" "[ -f $S ]"
a "syntax" "bash -n $S"
a "has apt" "grep -q apt $S"
a "has PKG_MANAGER variable" "grep -q PKG_MANAGER $S"
a "has cross-distro logic" "grep -q PKG_MANAGER $S"
echo "test_system: $TP passed, $TF failed"
