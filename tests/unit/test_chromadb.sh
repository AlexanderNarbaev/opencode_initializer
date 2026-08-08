#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
W="$P/src/lib/13-chromadb.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
a "exists" "[ -f $W ]"
a "syntax" "bash -n $W"
a "has ChromaDB" "grep -qi chromadb $W"
a "has systemd" "grep -q systemd $W"
a "has CHROMA auth config" "grep -q 'CHROMA_SERVER_AUTH' $W"
a "has chromadb.service unit" "grep -q 'chromadb.service' $W"
a "has port 8000" "grep -q '8000' $W"
echo "test_chromadb: $TP passed, $TF failed"
[ "$TF" -eq 0 ] || exit 1
