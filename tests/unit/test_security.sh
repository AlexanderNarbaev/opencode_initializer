#!/usr/bin/env bash
# Unit test: 15-security.sh — Trivy + Qodana + SBOM + daily scanning
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
W="$P/src/lib/15-security.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }
a "exists" "[ -f $W ]"
a "syntax" "bash -n $W"
a "has trivy scanner" "grep -q trivy $W"
a "has qodana" "grep -qi qodana $W"
a "has systemd timer" "grep -q systemctl $W"
a "has SBOM generation" "grep -qi sbom $W"
a "has snap install trivy" "grep -q 'snap install trivy' $W"
a "has apt fallback trivy" "grep -q 'apt install.*trivy' $W"
a "has _download_verify" "grep -q _download_verify $W"
a "has MODE guard" "grep -q 'MODE.*full.*reinit' $W"
a "has _step_done" "grep -q _step_done $W"
a "has section call" "grep -q 'section.*Security' $W"
a "has trivy scan service" "grep -q opencode-trivy-scan.service $W"
a "has trivy scan timer" "grep -q opencode-trivy-scan.timer $W"
a "has daemon-reload" "grep -q daemon-reload $W"
a "has cyclonedx format" "grep -q cyclonedx $W"
echo "test_security: $TP passed, $TF failed"
[ "$TF" -eq 0 ] || exit 1
