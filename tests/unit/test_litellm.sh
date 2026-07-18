#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
L="$P/src/lib/25-litellm.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
a "exists" "[ -f $L ]"
a "syntax" "bash -n $L"
a "has LiteLLM" "grep -qi litellm $L"
a "has OpenAI compat" "grep -qi openai $L"
a "has port 4000" "grep -q 4000 $L"
a "has proxy mention" "grep -q proxy $L"
echo "test_litellm: $TP passed, $TF failed"
