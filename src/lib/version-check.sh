#!/usr/bin/env bash
# lib/version-check.sh — Check installed versions against latest (for cron/dev CLI)
# Usage: source src/lib/version-check.sh && _check_versions
set -euo pipefail

_check_versions() {
  local updates=0 current latest

  echo "=== Version Check ($(date +%Y-%m-%d)) ==="

  # ── Rust ──
  if command -v rustc &>/dev/null; then
    current=$(rustc --version 2>/dev/null | awk '{print $2}')
    latest=$(curl -s --connect-timeout 5 --max-time 10 --retry 3 --retry-delay 2 'https://static.rust-lang.org/dist/channel-rust-stable.toml' 2>/dev/null | grep -A1 '\[pkg\.rustc\]' | grep version | awk -F'"' '{print $2}' | awk '{print $1}' || echo "$current")
    if [ "$current" != "$latest" ] && [ -n "$latest" ] && [ "$latest" != "$current" ]; then
      echo "  UPDATE: Rust $current → $latest"
      updates=$((updates + 1))
    else
      echo "  OK: Rust $current"
    fi
  fi

  # ── Go ──
  if command -v go &>/dev/null; then
    current=$(go version 2>/dev/null | awk '{print $3}' | tr -d 'go')
    latest=$(curl -s --connect-timeout 5 --max-time 10 --retry 3 --retry-delay 2 'https://go.dev/VERSION?m=text' 2>/dev/null | head -1 | tr -d 'go\n' || echo "$current")
    if [ "$current" != "$latest" ] && [ -n "$latest" ]; then
      echo "  UPDATE: Go $current → $latest"
      updates=$((updates + 1))
    else
      echo "  OK: Go $current"
    fi
  fi

  # ── Node.js ──
  if command -v node &>/dev/null; then
    current=$(node --version 2>/dev/null | tr -d 'v')
    latest=$(curl -s --connect-timeout 5 --max-time 10 --retry 3 --retry-delay 2 https://nodejs.org/dist/latest/SHASUMS256.txt 2>/dev/null | head -1 | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+' || echo "$current")
    if [ "$current" != "$latest" ] && [ -n "$latest" ]; then
      echo "  UPDATE: Node.js $current → $latest"
      updates=$((updates + 1))
    else
      echo "  OK: Node.js $current"
    fi
  fi

  # ── Python ──
  if command -v python3 &>/dev/null; then
    current=$(python3 --version 2>/dev/null | awk '{print $2}')
    latest=$(curl -s --connect-timeout 5 --max-time 10 --retry 3 --retry-delay 2 https://www.python.org/downloads/ 2>/dev/null | grep -oP 'Python \K3\.[0-9]+\.[0-9]+' | head -1 || echo "$current")
    if [ "$current" != "$latest" ] && [ -n "$latest" ]; then
      echo "  UPDATE: Python $current → $latest"
      updates=$((updates + 1))
    else
      echo "  OK: Python $current"
    fi
  fi

  # ── Bun ──
  if command -v bun &>/dev/null; then
    current=$(bun --version 2>/dev/null)
    latest=$(curl -s --connect-timeout 5 --max-time 10 --retry 3 --retry-delay 2 https://api.github.com/repos/oven-sh/bun/releases/latest 2>/dev/null | grep -oP '"tag_name": "bun-v\K[^"]+' | head -1 || echo "$current")
    if [ "$current" != "$latest" ] && [ -n "$latest" ]; then
      echo "  UPDATE: Bun $current → $latest"
      updates=$((updates + 1))
    else
      echo "  OK: Bun $current"
    fi
  fi

  # ── OpenCode ──
  if command -v opencode &>/dev/null; then
    current=$(opencode --version 2>/dev/null | head -1 | grep -oP '[\d]+\.[\d]+\.[\d]+' || echo "unknown")
    latest=$(curl -s --connect-timeout 5 --max-time 10 --retry 3 --retry-delay 2 https://api.github.com/repos/anomalyco/opencode/releases/latest 2>/dev/null | grep -oP '"tag_name": "v\K[^"]+' | head -1 || echo "$current")
    if [ "$current" != "$latest" ] && [ -n "$latest" ] && [ "$latest" != "$current" ]; then
      echo "  UPDATE: OpenCode $current → $latest"
      updates=$((updates + 1))
    else
      echo "  OK: OpenCode $current"
    fi
  fi

  # ── Ollama ──
  if command -v ollama &>/dev/null; then
    current=$(ollama --version 2>/dev/null | grep -oP '[\d]+\.[\d]+\.[\d]+' | head -1 || echo "unknown")
    latest=$(curl -s --connect-timeout 5 --max-time 10 --retry 3 --retry-delay 2 https://api.github.com/repos/ollama/ollama/releases/latest 2>/dev/null | grep -oP '"tag_name": "v\K[^"]+' | head -1 || echo "$current")
    if [ "$current" != "$latest" ] && [ -n "$latest" ] && [ "$latest" != "$current" ]; then
      echo "  UPDATE: Ollama $current → $latest"
      updates=$((updates + 1))
    else
      echo "  OK: Ollama $current"
    fi
  fi

  # ── Zig ──
  if command -v zig &>/dev/null; then
    current=$(zig version 2>/dev/null)
    latest=$(curl -s --connect-timeout 5 --max-time 10 --retry 3 --retry-delay 2 https://ziglang.org/download/index.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('master',{}).get('version',''))" 2>/dev/null || echo "$current")
    if [ "$current" != "$latest" ] && [ -n "$latest" ]; then
      echo "  UPDATE: Zig $current → $latest"
      updates=$((updates + 1))
    else
      echo "  OK: Zig $current"
    fi
  fi

  # ── Setup script itself ──
  if [ -f "$HOME/opencode_initializer/setup.sh" ]; then
    local_rev=$(git -C "$HOME/opencode_initializer" rev-parse HEAD 2>/dev/null || echo "?")
    remote_rev=$(git -C "$HOME/opencode_initializer" ls-remote origin HEAD 2>/dev/null | awk '{print $1}' || echo "$local_rev")
    if [ "$local_rev" != "$remote_rev" ] && [ "$local_rev" != "?" ] && [ "$remote_rev" != "" ]; then
      echo "  UPDATE: setup.sh has new commits on origin"
      updates=$((updates + 1))
    else
      echo "  OK: setup.sh up-to-date"
    fi
  fi

  # ── NPM global packages (key tools only) ──
  if command -v npm &>/dev/null; then
    for pkg in opencode-codegraph opencode-token-tracker opencode-orchestrator opencode-auto-fallback opencode-swarm chrome-devtools-mcp opencode-daytona opencode-background-agents opencode-scheduler opencode-supermemory @lyculs/opencode-firecrawl opencode-goal-plugin opencode-conductor @devtheops/opencode-plugin-otel @upstash/context7-mcp @notionhq/notion-mcp-server; do
      current=$(npm list -g "$pkg" 2>/dev/null | grep "$pkg" | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "?")
      latest=$(npm view "$pkg" version 2>/dev/null || echo "$current")
      if [ "$current" != "$latest" ] && [ -n "$latest" ] && [ "$current" != "?" ]; then
        echo "  UPDATE: $pkg $current → $latest"
        updates=$((updates + 1))
      elif [ "$current" != "?" ]; then
        echo "  OK: $pkg $current"
      fi
    done
  fi

  echo "=== $updates update(s) available ==="
  return $updates
}
