#!/usr/bin/env bash
# Unit test for src/lib/05-java.sh — existence, syntax, key patterns
set -euo pipefail

P="$(cd "$(dirname "$0")/../.." && pwd)"
W="$P/src/lib/05-java.sh"
TP=0; TF=0

a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }

a "exists" "[ -f $W ]"
a "syntax" "bash -n $W"
a "has Adoptium" "grep -qi adoptium $W"
a "has sdkman" "grep -q sdkman $W"
a "has java 25" "grep -q '25' $W"
a "has Gradle" "grep -qi gradle $W"
a "has Maven" "grep -qi maven $W"
a "has jbang" "grep -q jbang $W"
a "has Zig" "grep -qi zig $W"

echo "test_java: $TP passed, $TF failed"
[ "$TF" -eq 0 ] || exit 1
