#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
D="$P/src/lib/10-dotnet.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
a "exists" "[ -f $D ]"
a "syntax" "bash -n $D"
a "has dotnet-install" "grep -q dotnet-install $D"
a "has apt fallback" "grep -q apt $D"
a "has version" "grep -q dotnet-install $D"
echo "test_dotnet: $TP passed, $TF failed"
