#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
I="$P/src/lib/30-infra.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
a "exists" "[ -f $I ]"
a "syntax" "bash -n $I"
a "has PostgreSQL" "grep -qi postgres $I"
a "has Qdrant" "grep -qi qdrant $I"
a "has Redis" "grep -qi redis $I"
a "has Prometheus" "grep -qi prometheus $I"
a "has Grafana" "grep -qi grafana $I"
a "has Docker Compose" "grep -q compose $I"
a "has MemoryLayer" "grep -qi memorylayer $I"
a "has port config" "grep -q port.*[0-9] $I"
echo "test_infra: $TP passed, $TF failed"
