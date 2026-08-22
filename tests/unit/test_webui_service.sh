#!/usr/bin/env bash
# Unit test: 22-webui-service.sh — Open WebUI user service (systemd / launchd)
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

# ── User service (systemd / launchd via _service_install) ─────────────────
a "uses _service_install" "grep -q '_service_install \"open-webui\"' '$W'"
a "service has Description" "grep -q 'Open WebUI — LLM Chat Interface' '$W'"
a "service has OLLAMA_BASE_URL" "grep -q 'OLLAMA_BASE_URL' '$W'"
a "service has serve command" "grep -q 'serve --host 127.0.0.1 --port 3000' '$W'"
a "service layer in helpers.sh" "grep -q '_service_install()' '$P/src/lib/helpers.sh'"
a "helpers support launchd" "grep -q 'launchctl bootstrap' '$P/src/lib/helpers.sh'"
a "helpers support systemd" "grep -q 'systemctl --user' '$P/src/lib/helpers.sh'"

# ── Completion ────────────────────────────────────────────────────────────
a "has _step_done step_webui" "grep -q '_step_done.*step_webui' '$W'"

echo "test_webui_service: $TP passed, $TF failed"
[ "$TF" -eq 0 ] || exit 1
