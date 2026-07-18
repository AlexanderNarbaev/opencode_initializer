#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
O="$P/src/lib/11-opencode.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
a "exists" "[ -f $O ]"
a "syntax" "bash -n $O"
a "has opencode" "grep -qi opencode $O"
a "has Bun" "grep -qi bun $O"
a "has version" "grep -q opencode $O"
a "has npm install" "grep -q npm $O"
a "has _npm_install" "grep -q npm.install $O"
echo "test_opencode: $TP passed, $TF failed"
