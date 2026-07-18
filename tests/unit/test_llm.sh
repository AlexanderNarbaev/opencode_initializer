#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
L="$P/src/lib/16-llm.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
a "exists" "[ -f $L ]"
a "syntax" "bash -n $L"
a "has Ollama" "grep -q ollama $L"
a "has vLLM" "grep -q vllm $L"
a "has SGLang" "grep -q sglang $L"
a "has Open WebUI" "grep -q webui $L"
a "has GPU detection" "grep -qi nvidia $L"
a "has WasmEdge" "grep -q wasmedge $L"
a "has service setup" "grep -q systemd $L"
a "has model pull" "grep -q ollama pull $L"
echo "test_llm: $TP passed, $TF failed"
