#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
W="$P/src/lib/21-rag.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
a "exists" "[ -f $W ]"
a "syntax" "bash -n $W"
a "has RAG" "grep -qi 'RAG\|rag' $W"
a "has Qdrant" "grep -qi qdrant $W"
a "has ETL" "grep -q 'etl\|ETL' $W"
a "has proxy" "grep -q proxy $W"
a "has rag-system repo" "grep -q 'rag-system' $W"
echo "test_rag: $TP passed, $TF failed"
[ "$TF" -eq 0 ] || exit 1
