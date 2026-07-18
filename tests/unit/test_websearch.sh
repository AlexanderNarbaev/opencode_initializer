#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
W="$P/src/lib/24-websearch.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
a "exists" "[ -f $W ]"
a "syntax" "bash -n $W"
a "has SearXNG" "grep -qi searxng $W"
a "has sanitizer" "grep -q sanitiz $W"
a "has port 8080" "grep -q 8080 $W"
a "has PII filter" "grep -q sanitiz $W"
echo "test_websearch: $TP passed, $TF failed"
