#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
R="$P/src/lib/09-rust.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
a "exists" "[ -f $R ]"
a "syntax" "bash -n $R"
a "has rustup" "grep -q rustup $R"
a "has cargo" "grep -q cargo $R"
a "has stable toolchain" "grep -q stable $R"
echo "test_rust: $TP passed, $TF failed"
