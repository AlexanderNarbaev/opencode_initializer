#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
PY="$P/src/lib/07-python.sh"
D="$P/src/lib/02-docker.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
a "python exists" "[ -f $PY ]"
a "python syntax" "bash -n $PY"
a "python has uv" "grep -q uv $PY"
a "python has pip" "grep -q pip $PY"
a "docker exists" "[ -f $D ]"
a "docker syntax" "bash -n $D"
a "docker has apt" "grep -q apt $D"
a "docker has systemctl" "grep -q systemctl $D"
echo "test_python_docker: $TP passed, $TF failed"
