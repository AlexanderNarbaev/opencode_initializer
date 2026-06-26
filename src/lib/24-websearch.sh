#!/usr/bin/env bash
# src/lib/24-websearch.sh — SearXNG web search + sanitizer proxy + MCP server
# Installs SearXNG Docker container, sanitizer proxy, and mcp-searxng MCP server
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_SYSTEM"; then
  section "SearXNG — Web Search Engine"

  SANITIZER_PORT=8888
  SEARXNG_PORT=8080
  SEARXNG_CONFIG_DIR="$HOME/.config/searxng"
  SANITIZER_BIN="$HOME/.local/bin/search-sanitizer"
  SANITIZER_CONFIG="$HOME/.config/opencode-setup/sanitizer-rules.conf"
  SANITIZER_LOG="$HOME/.cache/opencode-setup/sanitizer.log"
  SEARXNG_SETTINGS="$SEARXNG_CONFIG_DIR/settings.yml"

  mkdir -p "$HOME/.local/bin"
  mkdir -p "$(dirname "$SANITIZER_CONFIG")"
  mkdir -p "$(dirname "$SANITIZER_LOG")"
  touch "$SANITIZER_LOG"

  # ── Sanitizer rules config ──────────────────────────────────────────────────
  if [ ! -f "$SANITIZER_CONFIG" ]; then
    cat > "$SANITIZER_CONFIG" << 'RULESEOF'
# SearXNG sanitizer rules — strip sensitive data from search results
# EDIT CAREFULLY: one pattern per line, blank lines and # comments ignored.

[hostname_patterns]
*.cloudx.local
*.internal.cloudx
*.cloudx.internal
*.corp.internal
*.intranet.local
*.dev.internal

[ip_ranges]
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
100.64.0.0/10
127.0.0.0/8
169.254.0.0/16

[secret_patterns]
api[_-]?key[=:]\s*["']?[A-Za-z0-9_\-]{16,}
Bearer\s+[A-Za-z0-9_\-\.=]{20,}
[Pp]assword[=:]\s*["']?[^\s"']{4,}
[Pp]asswd[=:]\s*["']?[^\s"']{4,}
[Pp]rivate[_-]?key[=:]\s*["']?[^\s"']+
[Ii]nternal[_-]?url[=:]\s*["']?[^\s"']+
[Aa]uth[_-]?token[=:]\s*["']?[A-Za-z0-9_\-\.]{16,}
[Oo]auth[=:]\s*["']?[A-Za-z0-9_\-\.]{16,}
[Ll]icense[_-]?[Kk]ey[=:]\s*["']?[^\s"']+
RULESEOF
    log "Sanitizer rules created: $SANITIZER_CONFIG"
  else
    log "Sanitizer rules config already exists"
  fi

  # ── SearXNG Docker container ────────────────────────────────────────────────
  if command -v docker &>/dev/null; then
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q '^searxng$'; then
      if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^searxng$'; then
        docker start searxng 2>/dev/null && log "SearXNG container restarted" || warn "SearXNG: failed to start"
      else
        log "SearXNG container already running"
      fi
    else
      log "Pulling SearXNG Docker image..."
      docker pull searxng/searxng:latest 2>/dev/null || true
      mkdir -p "$SEARXNG_CONFIG_DIR"
      docker run -d --name searxng \
        -p "${SEARXNG_PORT}:8080" \
        -v "${SEARXNG_CONFIG_DIR}:/etc/searxng" \
        --restart unless-stopped \
        searxng/searxng:latest 2>/dev/null && \
        log "SearXNG container started (port $SEARXNG_PORT)" || \
        warn "SearXNG: Docker run failed — check manually"
    fi

    # Generate settings.yml with privacy-focused defaults if not present
    if [ ! -f "$SEARXNG_SETTINGS" ]; then
      # Wait a moment for container to initialize
      sleep 3
      docker exec searxng cat /etc/searxng/settings.yml 2>/dev/null > "$SEARXNG_SETTINGS" || true
      if [ -f "$SEARXNG_SETTINGS" ]; then
        # Disable search logging for privacy
        sed -i 's/search:\s*\(\.*\)/search:\n    safe_search: 0\n    autocomplete: ""\n    default_lang: ""/' "$SEARXNG_SETTINGS" 2>/dev/null || true
        # Copy back into container
        docker cp "$SEARXNG_SETTINGS" searxng:/etc/searxng/settings.yml 2>/dev/null || true
        docker restart searxng 2>/dev/null || true
        log "SearXNG settings configured"
      fi
    fi

    # Wait for SearXNG to be ready
    for i in $(seq 1 15); do
      if curl -sf "http://localhost:${SEARXNG_PORT}/search?q=test" &>/dev/null; then
        log "SearXNG API reachable on port $SEARXNG_PORT"
        break
      fi
      [ "$i" -eq 15 ] && warn "SearXNG: not reachable after 15 retries — continuing"
      sleep 2
    done
  else
    warn "Docker not installed — SearXNG requires Docker"
  fi

  # ── Sanitizer proxy Python script ───────────────────────────────────────────
  cat > "$SANITIZER_BIN" << 'PYPROXY'
#!/usr/bin/env python3
"""search-sanitizer — HTTP proxy that strips sensitive data from SearXNG results.

Listens on _SANITIZER_PORT, forwards requests to SearXNG at _SEARXNG_URL,
and strips sensitive patterns from JSON responses before returning them.

Usage:
    search-sanitizer [--port PORT] [--target URL] [--config FILE]
"""
import http.server
import json
import ipaddress
import re
import sys
import os
import urllib.request
import urllib.error
import fnmatch
from datetime import datetime, timezone

SANITIZER_PORT = 8888
SEARXNG_URL = "http://localhost:8080"
CONFIG_PATH = os.path.expanduser("~/.config/opencode-setup/sanitizer-rules.conf")
LOG_PATH = os.path.expanduser("~/.cache/opencode-setup/sanitizer.log")

# ── Rule loading ──────────────────────────────────────────────────────────────
def load_rules(config_path):
    """Parse sanitizer-rules.conf into structured rule sets."""
    rules = {
        "hostname_patterns": [],
        "ip_networks": [],
        "secret_regexes": [],
        "extra_patterns": [],
    }
    section = None
    try:
        with open(config_path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if line.startswith("[") and line.endswith("]"):
                    section = line[1:-1]
                    continue
                if section == "hostname_patterns":
                    rules["hostname_patterns"].append(line)
                elif section == "ip_ranges":
                    try:
                        rules["ip_networks"].append(ipaddress.ip_network(line, strict=False))
                    except ValueError:
                        pass
                elif section == "secret_patterns":
                    try:
                        rules["secret_regexes"].append(re.compile(line, re.IGNORECASE))
                    except re.error:
                        pass
                elif section == "extra_patterns":
                    rules["extra_patterns"].append(line)
    except FileNotFoundError:
        print(f"[sanitizer] WARNING: config not found at {config_path}", file=sys.stderr)
    return rules

# ── IP matching ───────────────────────────────────────────────────────────────
def is_internal_ip(ip_str, networks):
    """Check if an IP address falls within any internal network range."""
    try:
        addr = ipaddress.ip_address(ip_str.strip())
        return any(addr in net for net in networks)
    except ValueError:
        return False

# ── Hostname matching ─────────────────────────────────────────────────────────
def is_internal_hostname(hostname, patterns):
    """Check if hostname matches any internal pattern (glob)."""
    for pattern in patterns:
        if fnmatch.fnmatch(hostname.lower(), pattern.lower()):
            return True
    return False

# ── Content sanitization ──────────────────────────────────────────────────────
REDACTED = "[REDACTED]"

def sanitize_text(text, rules):
    """Strip sensitive patterns from a text string. Returns (cleaned, count)."""
    count = 0
    for regex in rules["secret_regexes"]:
        matches = regex.findall(text)
        if matches:
            text = regex.sub(REDACTED, text)
            count += len(matches)
    return text, count

def sanitize_url(url, rules):
    """Check if URL contains internal hostname/IP. Returns (cleaned, stripped_bool)."""
    try:
        from urllib.parse import urlparse
        parsed = urlparse(url)
        hostname = parsed.hostname or ""
        if hostname:
            if is_internal_hostname(hostname, rules["hostname_patterns"]):
                return REDACTED, True
            try:
                ip = ipaddress.ip_address(hostname)
                if any(ip in net for net in rules["ip_networks"]):
                    return REDACTED, True
            except ValueError:
                pass
    except Exception:
        pass
    return url, False

def sanitize_result(result, rules):
    """Sanitize a single search result dict. Returns (cleaned_result, strip_count)."""
    sanitized = dict(result)
    total_stripped = 0

    for field in ("title", "content", "snippet", "engine", "category"):
        if field in sanitized and isinstance(sanitized[field], str):
            text, count = sanitize_text(sanitized[field], rules)
            if count > 0:
                sanitized[field] = text
                total_stripped += count

    if "url" in sanitized and isinstance(sanitized["url"], str):
        new_url, stripped = sanitize_url(sanitized["url"], rules)
        if stripped:
            sanitized["url"] = new_url
            total_stripped += 1

    for key in list(sanitized.keys()):
        if isinstance(sanitized[key], str):
            text, count = sanitize_text(sanitized[key], rules)
            if count > 0:
                sanitized[key] = text
                total_stripped += count

    return sanitized, total_stripped

def sanitize_json(data, rules):
    """Recursively sanitize search result JSON. Returns (cleaned_data, total_stripped)."""
    total = 0
    if isinstance(data, dict):
        sanitized = {}
        for key, value in data.items():
            if key in ("results",) and isinstance(value, list):
                clean_results = []
                for item in value:
                    clean_item, count = sanitize_result(item, rules)
                    clean_results.append(clean_item)
                    total += count
                sanitized[key] = clean_results
            elif isinstance(value, (dict, list)):
                sub, count = sanitize_json(value, rules)
                sanitized[key] = sub
                total += count
            elif isinstance(value, str):
                text, count = sanitize_text(value, rules)
                sanitized[key] = text
                total += count
            else:
                sanitized[key] = value
        return sanitized, total
    elif isinstance(data, list):
        return [sanitize_json(item, rules)[0] for item in data], total
    elif isinstance(data, str):
        text, count = sanitize_text(data, rules)
        return text, total
    return data, total

# ── Sanitizer proxy handler ──────────────────────────────────────────────────
class SanitizerHandler(http.server.BaseHTTPRequestHandler):
    rules = None

    def do_GET(self):
        self._proxy_request()

    def do_POST(self):
        self._proxy_request()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()

    def _proxy_request(self):
        target_url = SEARXNG_URL + self.path
        body = None
        content_length = int(self.headers.get("Content-Length", 0))
        if content_length > 0:
            body = self.rfile.read(content_length)

        req = urllib.request.Request(
            target_url,
            data=body,
            headers={k: v for k, v in self.headers.items()
                     if k.lower() not in ("host", "connection")},
            method=self.command,
        )

        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                resp_body = resp.read()
                resp_headers = dict(resp.headers)

                content_type = resp_headers.get("Content-Type", resp_headers.get("content-type", ""))
                stripped_count = 0

                if "json" in content_type and resp_body:
                    try:
                        data = json.loads(resp_body)
                        data, stripped_count = sanitize_json(data, SanitizerHandler.rules)
                        resp_body = json.dumps(data, ensure_ascii=False).encode("utf-8")
                    except (json.JSONDecodeError, UnicodeDecodeError):
                        pass

                if stripped_count > 0:
                    self._log_action(f"Stripped {stripped_count} sensitive items from {self.path}")

                self.send_response(resp.status)
                for key, value in resp_headers.items():
                    if key.lower() not in ("transfer-encoding", "connection"):
                        self.send_header(key, value)
                self.send_header("Content-Length", str(len(resp_body)))
                self.end_headers()
                self.wfile.write(resp_body)

        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.end_headers()
            self.wfile.write(e.read() or b"")
        except Exception as e:
            self.send_response(502)
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode("utf-8"))

    def _log_action(self, msg):
        try:
            with open(LOG_PATH, "a") as logf:
                ts = datetime.now(timezone.utc).isoformat()
                logf.write(f"[{ts}] {msg}\n")
        except OSError:
            pass

    def log_message(self, format, *args):
        pass

def main():
    global SANITIZER_PORT, SEARXNG_URL, CONFIG_PATH

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--port" and i + 1 < len(args):
            SANITIZER_PORT = int(args[i + 1]); i += 2
        elif args[i] == "--target" and i + 1 < len(args):
            SEARXNG_URL = args[i + 1]; i += 2
        elif args[i] == "--config" and i + 1 < len(args):
            CONFIG_PATH = args[i + 1]; i += 2
        else:
            print(f"Usage: {sys.argv[0]} [--port PORT] [--target URL] [--config FILE]", file=sys.stderr)
            sys.exit(1)

    SanitizerHandler.rules = load_rules(CONFIG_PATH)
    rules = SanitizerHandler.rules
    print(f"[sanitizer] Loaded {len(rules['hostname_patterns'])} host patterns, "
          f"{len(rules['ip_networks'])} IP ranges, "
          f"{len(rules['secret_regexes'])} secret regexes",
          file=sys.stderr)

    server = http.server.HTTPServer(("127.0.0.1", SANITIZER_PORT), SanitizerHandler)
    print(f"[sanitizer] Proxy listening on 127.0.0.1:{SANITIZER_PORT} → {SEARXNG_URL}", file=sys.stderr)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[sanitizer] Shutting down", file=sys.stderr)
        server.server_close()

if __name__ == "__main__":
    main()
PYPROXY
  chmod +x "$SANITIZER_BIN"
  log "Sanitizer proxy installed: $SANITIZER_BIN"

  # ── Install mcp-searxng MCP server ─────────────────────────────────────────
  if command -v npm &>/dev/null || command -v bun &>/dev/null; then
    _npm_install "mcp-searxng" "websearch" || true
  else
    warn "websearch MCP: npm/bun not available — skipping"
  fi

  # ── Start sanitizer proxy in background ────────────────────────────────────
  if ! curl -sf "http://localhost:${SANITIZER_PORT}/search?q=test" &>/dev/null 2>&1; then
    "$SANITIZER_BIN" --port "$SANITIZER_PORT" --target "http://localhost:${SEARXNG_PORT}" &
    SANITIZER_PID=$!
    disown $SANITIZER_PID 2>/dev/null || true
    sleep 1
    if curl -sf "http://localhost:${SANITIZER_PORT}/search?q=test" &>/dev/null 2>&1; then
      log "Sanitizer proxy started (PID $SANITIZER_PID, port $SANITIZER_PORT)"
    else
      warn "Sanitizer proxy: failed to start — MCP will connect directly to SearXNG"
    fi
  else
    log "Sanitizer proxy already running on port $SANITIZER_PORT"
  fi

  # ── Systemd user service for sanitizer auto-start ──────────────────────────
  if command -v systemctl &>/dev/null; then
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$HOME/.config/systemd/user/search-sanitizer.service" << SVCUNIT
[Unit]
Description=Search Sanitizer Proxy (SearXNG filter)
After=network.target docker.service

[Service]
Type=simple
ExecStart=$SANITIZER_BIN --port $SANITIZER_PORT --target http://localhost:$SEARXNG_PORT
ExecStartPost=/bin/bash -c 'for i in \$(seq 1 10); do curl -sf http://127.0.0.1:$SANITIZER_PORT/search?q=test 2>/dev/null && exit 0; sleep 1; done; exit 0'
Restart=on-failure
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=default.target
SVCUNIT
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable search-sanitizer.service 2>/dev/null || true
    log "Sanitizer systemd service installed"
  fi

  _step_done step_websearch
  log "Web search (SearXNG + sanitizer + MCP) configured"
fi
