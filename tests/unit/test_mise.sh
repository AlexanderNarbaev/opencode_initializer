#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
W="$P/src/lib/29-mise.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
a "exists" "[ -f $W ]"
a "syntax" "bash -n $W"
a "has mise" "grep -q mise $W"
a "has tool version" "grep -q 'tool.*version\|version.*manager' $W"
a "has install/binary" "grep -qE 'install|binary|curl|download' $W"
a "has config" "grep -q config $W"
echo "test_mise: $TP passed, $TF failed"
[ "$TF" -eq 0 ] || exit 1
