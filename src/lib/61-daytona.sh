#!/usr/bin/env bash
# lib/61-daytona.sh — Daytona Environment Practice (STEP 61)
# Installs the CURRENT Daytona platform CLI (the legacy daytonaio
# workspace-manager OSS project was archived in June 2026 — do NOT use
# get.daytona.io), writes a declarative environments registry config, and
# installs a `daytona-env` wrapper that turns config entries into CLI
# commands. Flexible environment setup both ways: imperative commands AND
# declarative config files. Auth via DAYTONA_API_KEY env var only — secrets
# are never stored in the registry.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_step_skip step_daytona && return 0

# Opt-out (matches SKIP_DOTFILES / SKIP_DEVBOX / SKIP_GUI convention)
[ "${SKIP_DAYTONA:-false}" = "true" ] && { info "Daytona skipped (SKIP_DAYTONA=true)"; return 0; }

section "Daytona Environment Practice — CLI + declarative registry + wrapper"

# ── Install the Daytona platform CLI ────────────────────────────────────────
_install_daytona_cli() {
  if command -v daytona >/dev/null 2>&1; then
    log "daytona already present ($(daytona --version 2>/dev/null || echo 'unknown version'))"
    return 0
  fi

  # macOS + Homebrew path
  if [ "$(uname -s)" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
    _spin_start "Installing daytona via Homebrew (daytonaio/cli/daytona)"
    if brew install daytonaio/cli/daytona >/dev/null 2>&1; then
      _spin_stop "✓"
      log "daytona installed (brew)"
      return 0
    fi
    _spin_stop "✗"
    warn "daytona brew install failed"
    return 1
  fi

  # Direct binary from GitHub releases (latest)
  local os arch asset tmp
  case "$(uname -s)" in
    Linux)  os="linux" ;;
    Darwin) os="darwin" ;;
    *) warn "Unsupported OS for daytona binary install: $(uname -s)"; return 1 ;;
  esac
  case "$(uname -m)" in
    x86_64)        arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) warn "Unsupported arch for daytona binary install: $(uname -m)"; return 1 ;;
  esac
  asset="daytona-${os}-${arch}"

  tmp="$(mktemp /tmp/daytona.XXXXXX)"
  _spin_start "Downloading daytona CLI ($asset)"
  if _curl "https://github.com/daytonaio/daytona/releases/latest/download/${asset}" "$tmp" 2>/dev/null; then
    _spin_stop "✓"
  else
    _spin_stop "✗"
    warn "daytona download failed"
    rm -f "$tmp"
    return 1
  fi

  _sudo install -m 0755 "$tmp" /usr/local/bin/daytona || { rm -f "$tmp"; warn "daytona install to /usr/local/bin failed"; return 1; }
  rm -f "$tmp"

  if command -v daytona >/dev/null 2>&1; then
    log "daytona installed"
    return 0
  fi
  warn "daytona install verification failed"
  return 1
}

# ── Write the declarative environments registry ─────────────────────────────
_write_daytona_env_config() {
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/daytona/environments.json"
  mkdir -p "$(dirname "$cfg")"
  cat > "$cfg" <<'EOF'
{
  "version": 1,
  "managed_by": "opencode_initializer@61-daytona",
  "note": "Auth via DAYTONA_API_KEY env var only — never store secrets here.",
  "defaults": {
    "cpu": 2,
    "memory_gb": 4,
    "disk_gb": 10,
    "auto_stop_minutes": 15,
    "target": "us"
  },
  "environments": [
    {
      "name": "dev-minimal",
      "image": { "snapshot": "debian-slim" },
      "labels": ["dev"]
    },
    {
      "name": "dev-node",
      "image": { "dockerfile": "./Dockerfile" },
      "env": { "NODE_ENV": "development" },
      "auto_stop_minutes": 30
    }
  ]
}
EOF
  log "Wrote $cfg"
}

# ── Install the daytona-env wrapper ─────────────────────────────────────────
# Prefers copying the repo's canonical scripts/daytona-env.sh (single source
# of truth); falls back to an inline heredoc when the repo copy is absent.
_install_daytona_env_wrapper() {
  local bin="$HOME/.local/bin/daytona-env"
  mkdir -p "$HOME/.local/bin"

  if [ -f "$SCRIPT_DIR/../scripts/daytona-env.sh" ]; then
    cp "$SCRIPT_DIR/../scripts/daytona-env.sh" "$bin"
  else
    cat > "$bin" <<'EOF'
#!/usr/bin/env bash
# daytona-env — fallback wrapper (see opencode_initializer scripts/daytona-env.sh)
echo "daytona-env: canonical implementation missing — rerun setup.sh step_daytona" >&2
exit 1
EOF
  fi
  chmod +x "$bin"
  log "Installed daytona-env wrapper at $bin"
}

# ── Health check ─────────────────────────────────────────────────────────────
_check_daytona_health() {
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/daytona/environments.json"
  local ok=true
  if ! command -v daytona >/dev/null 2>&1; then warn "daytona CLI missing"; ok=false; fi
  if [ ! -f "$cfg" ]; then warn "environments.json missing"; ok=false; fi
  if [ ! -x "$HOME/.local/bin/daytona-env" ]; then warn "daytona-env wrapper missing"; ok=false; fi
  $ok && log "Daytona: OK" || return 1
}

# ── Main ─────────────────────────────────────────────────────────────────────
_install_daytona_cli || true
_write_daytona_env_config
_install_daytona_env_wrapper
_check_daytona_health || true
_step_done step_daytona
