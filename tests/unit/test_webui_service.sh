#!/usr/bin/env bash
# Unit test: 22-webui-service.sh — Open WebUI systemd user service
set -euo pipefail

TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }

P="$(cd "$(dirname "$0")/../.." && pwd)"
W="$P/src/lib/22-webui-service.sh"

echo "=== Testing 22-webui-service.sh ==="

# ── File existence & syntax ──────────────────────────────────────────────
a "22-webui-service.sh exists" "[ -f '$W' ]"
a "22-webui-service.sh syntax" "bash -n '$W'"

# ── Mode gating ───────────────────────────────────────────────────────────
a "has MODE=full gate" "grep -q 'MODE.*=.*full' '$W'"
a "has MODE=reinit gate" "grep -q 'MODE.*=.*reinit' '$W'"
a "has INTERACTIVE_DO_LLM gate" "grep -q 'INTERACTIVE_DO_LLM' '$W'"

# ── Section header ────────────────────────────────────────────────────────
a "has section Open WebUI" "grep -q 'section.*Open WebUI' '$W'"

# ── Installation checks ───────────────────────────────────────────────────
a "has open-webui command check" "grep -q 'command -v open-webui' '$W'"
a "has uv tool install" "grep -q 'uv tool install' '$W'"
a "has pipx install fallback" "grep -q 'pipx install' '$W'"
a "has pip install fallback" "grep -q 'pip install.*open-webui' '$W'"

# ── Systemd service ───────────────────────────────────────────────────────
a "has mkdir systemd/user" "grep -q 'systemd/user' '$W'"
a "has open-webui.service creation" "grep -q 'open-webui.service' '$W'"
a "service has Description" "grep -q 'Description=Open WebUI' '$W'"
a "service has After=network.target" "grep -q 'After=network.target' '$W'"
a "service has Type=simple" "grep -q 'Type=simple' '$W'"
a "service has OLLAMA_BASE_URL" "grep -q 'OLLAMA_BASE_URL' '$W'"
a "service has ExecStart" "grep -q 'ExecStart=' '$W'"
a "service has Restart=on-failure" "grep -q 'Restart=on-failure' '$W'"
a "service has RestartSec" "grep -q 'RestartSec=' '$W'"
a "service has WantedBy=default.target" "grep -q 'WantedBy=default.target' '$W'"

# ── Systemctl commands ────────────────────────────────────────────────────
a "has systemctl daemon-reload" "grep -q 'daemon-reload' '$W'"
a "has systemctl enable" "grep -q 'systemctl.*enable' '$W'"
a "has systemctl start" "grep -q 'systemctl.*start' '$W'"

# ── Completion ────────────────────────────────────────────────────────────
a "has _step_done step_webui" "grep -q '_step_done.*step_webui' '$W'"

echo "test_webui_service: $TP passed, $TF failed"
[ "$TF" -eq 0 ] || exit 1
