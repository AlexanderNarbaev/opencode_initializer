#!/usr/bin/env bash
# Unit test: 24-websearch.sh — SearXNG web search + sanitizer proxy + MCP
# Session: ses_websearch_expand
set -euo pipefail

TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }

P="$(cd "$(dirname "$0")/../.." && pwd)"
W="$P/src/lib/24-websearch.sh"

echo "=== Testing 24-websearch.sh ==="

# ── File existence & syntax ──────────────────────────────────────────────────
a "24-websearch.sh exists" "[ -f '$W' ]"
a "24-websearch.sh syntax" "bash -n '$W'"
a "has shebang" "head -1 '$W' | grep -q '#!/usr/bin/env bash'"
a "has set -euo pipefail" "grep -q 'set -euo pipefail' '$W'"

# ── Mode gating ───────────────────────────────────────────────────────────────
a "has MODE=full gate" "grep -q 'MODE.*=.*full' '$W'"
a "has MODE=reinit gate" "grep -q 'MODE.*=.*reinit' '$W'"
a "has INTERACTIVE_DO_SYSTEM gate" "grep -q 'INTERACTIVE_DO_SYSTEM' '$W'"

# ── Section header ────────────────────────────────────────────────────────────
a "has section SearXNG" "grep -q 'section.*SearXNG' '$W'"

# ── Port configuration ────────────────────────────────────────────────────────
a "defines SANITIZER_PORT=8888" "grep -q 'SANITIZER_PORT=8888' '$W'"
a "defines SEARXNG_PORT=8080" "grep -q 'SEARXNG_PORT=8080' '$W'"

# ── SearXNG configuration ─────────────────────────────────────────────────────
a "has SEARXNG_CONFIG_DIR" "grep -q 'SEARXNG_CONFIG_DIR' '$W'"
a "has SEARXNG_SETTINGS (settings.yml)" "grep -q 'SEARXNG_SETTINGS' '$W'"
a "has settings.yml path" "grep -q 'settings.yml' '$W'"
a "has Docker container searxng" "grep -q 'docker.*searxng' '$W'"
a "has docker pull searxng" "grep -q 'docker pull.*searxng' '$W'"
a "has docker run searxng" "grep -q 'docker run' '$W'"
a "has health check curl localhost (SearXNG)" "grep -q 'localhost.*SEARXNG_PORT.*search' '$W'"

# ── Sanitizer config ──────────────────────────────────────────────────────────
a "has SANITIZER_BIN" "grep -q 'SANITIZER_BIN' '$W'"
a "has SANITIZER_CONFIG" "grep -q 'SANITIZER_CONFIG' '$W'"
a "defines hostname_patterns section" "grep -q 'hostname_patterns' '$W'"
a "defines ip_ranges section" "grep -q 'ip_ranges' '$W'"
a "has private IP 10.0.0.0/8" "grep -q '10\.0\.0\.0/8' '$W'"
a "has private IP 192.168.0.0/16" "grep -q '192\.168\.0\.0/16' '$W'"
a "defines secret_patterns section" "grep -q 'secret_patterns' '$W'"
a "has API key pattern" "grep -q 'api.*key' '$W'"
a "has Bearer token pattern" "grep -q 'Bearer' '$W'"
a "has internal hostname filter (*.internal.local)" "grep -q 'internal\.local' '$W'"

# ── Sanitizer proxy Python script ─────────────────────────────────────────────
a "has Python proxy script" "grep -q '#!/usr/bin/env python3' '$W'"
a "has sanitize_text function" "grep -q 'def sanitize_text' '$W'"
a "has sanitize_url function" "grep -q 'def sanitize_url' '$W'"
a "has sanitize_result function" "grep -q 'def sanitize_result' '$W'"
a "has sanitize_json function" "grep -q 'def sanitize_json' '$W'"
a "has REDACTED constant" "grep -q 'REDACTED' '$W'"
a "has is_internal_ip check" "grep -q 'def is_internal_ip' '$W'"
a "has is_internal_hostname check" "grep -q 'def is_internal_hostname' '$W'"
a "has fnmatch for hostname matching" "grep -q 'fnmatch' '$W'"
a "has ipaddress module" "grep -q 'import ipaddress' '$W'"
a "has urllib.request import" "grep -q 'urllib.request' '$W'"
a "proxy sanitizes title/content/snippet" "grep -q 'title.*content.*snippet' '$W'"

# ── MCP server ────────────────────────────────────────────────────────────────
a "has mcp-searxng install" "grep -q 'mcp-searxng' '$W'"
a "has _npm_install call" "grep -q '_npm_install' '$W'"

# ── Systemd service ───────────────────────────────────────────────────────────
a "has search-sanitizer.service" "grep -q 'search-sanitizer.service' '$W'"
a "service has Description=Search Sanitizer" "grep -q 'Description=Search Sanitizer' '$W'"
a "service has After=network.target" "grep -q 'After=network.target' '$W'"
a "service has Type=simple" "grep -q 'Type=simple' '$W'"
a "service has ExecStart" "grep -q 'ExecStart=' '$W'"
a "service has Restart=on-failure" "grep -q 'Restart=on-failure' '$W'"

# ── Step completion ───────────────────────────────────────────────────────────
a "has _step_done step_websearch" "grep -q '_step_done step_websearch' '$W'"

# ── Error handling ────────────────────────────────────────────────────────────
a "warns when Docker not installed" "grep -q 'Docker not installed' '$W'"
a "warns on sanitizer startup failure" "grep -q 'failed to start' '$W'"

# ── Results ───────────────────────────────────────────────────────────────────
echo "test_websearch: $TP passed, $TF failed"
[ "$TF" -eq 0 ] || exit 1
