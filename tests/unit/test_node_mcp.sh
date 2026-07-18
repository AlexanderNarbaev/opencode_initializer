#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
N="$P/src/lib/06-node.sh"
a "node exists" "[ -f $N ]"
a "node syntax" "bash -n $N"
a "has n version mgr" "grep -q n. $N"
a "has npm" "grep -q npm $N"
M="$P/src/lib/12-mcp-lsp.sh"
a "mcp exists" "[ -f $M ]"
a "mcp syntax" "bash -n $M"
a "has MCP" "grep -qi mcp $M"
a "has LSP" "grep -qi lsp $M"
a "has bun bin paths" "grep -q bun.bin $M"
echo "test_node_mcp: $TP passed, $TF failed"
