#!/usr/bin/env bash
# src/lib/00i-mirrors.sh — GitVerse Mirror Configuration (v4.1.0)
# Configures all package manager mirrors for RU/CN regions.
# Source: https://gitverse.ru/docs/artifactory/registry-mirrors/
set -euo pipefail

# ── Mirror URLs (GitVerse Artifactory) ───────────────────────────────────────
# Primary mirrors for RU region
GITVERSE_NPM_MIRROR="https://npm-mirror.gitverse.ru"
GITVERSE_PYPI_MIRROR="https://pypi-mirror.gitverse.ru/simple/"
GITVERSE_GO_MIRROR="https://go-mirror.gitverse.ru"
GITVERSE_CRATES_MIRROR="https://crates-mirror.gitverse.ru"
GITVERSE_DOCKER_MIRROR="https://dh-mirror.gitverse.ru"
GITVERSE_MAVEN_MIRROR="https://mvn-mirror.gitverse.ru"

# CN mirrors (fallback)
CN_NPM_MIRROR="https://registry.npmmirror.com"
CN_PYPI_MIRROR="https://pypi.tuna.tsinghua.edu.cn/simple/"
CN_GO_MIRROR="https://goproxy.cn"
CN_CRATES_MIRROR="https://rsproxy.cn/crates.io-index"
CN_DOCKER_MIRROR="https://mirror.ccs.tencentyun.com"

# ── Detect region ────────────────────────────────────────────────────────────
# Usage: region=$(_detect_region)
# Returns: "ru", "cn", or "global"
_detect_region() {
  local tz
  # Try multiple methods to detect timezone
  if [ -n "${TZ:-}" ]; then
    tz="$TZ"
  elif [ -f /etc/timezone ]; then
    tz=$(cat /etc/timezone 2>/dev/null || echo "UTC")
  elif command -v timedatectl &>/dev/null; then
    tz=$(timedatectl show -p Timezone --value 2>/dev/null || echo "UTC")
  else
    tz="UTC"
  fi

  case "$tz" in
    Europe/Moscow|Europe/Samara|Europe/Volgograd|Asia/Yekaterinburg|Asia/Omsk|Asia/Novosibirsk|Asia/Irkutsk|Asia/Yakutsk|Asia/Vladivostok|Asia/Kamchatka|Asia/Magadan|Asia/Sakhalin|Asia/Chita|Asia/Krasnoyarsk|Asia/Tomsk)
      echo "ru"
      ;;
    Asia/Shanghai|Asia/Chongqing|Asia/Harbin|Asia/Urumqi|Asia/Kashgar|Asia/Hong_Kong|Asia/Macau)
      echo "cn"
      ;;
    *)
      echo "global"
      ;;
  esac
}

# ── Configure NPM mirror ────────────────────────────────────────────────────
# Usage: _configure_npm_mirror [region]
_configure_npm_mirror() {
  local region="${1:-$(_detect_region)}"
  local mirror=""

  case "$region" in
    ru) mirror="$GITVERSE_NPM_MIRROR" ;;
    cn) mirror="$CN_NPM_MIRROR" ;;
    *)  return 0 ;;  # Use default
  esac

  info "Configuring NPM mirror: $mirror"

  # Set via npm config
  npm config set registry "$mirror" 2>/dev/null || true

  # Set via environment variable
  export npm_config_registry="$mirror"

  # Create/update .npmrc
  local npmrc="$HOME/.npmrc"
  if [ -f "$npmrc" ]; then
    # Update existing
    if grep -q "^registry=" "$npmrc"; then
      sed -i "s|^registry=.*|registry=$mirror|" "$npmrc"
    else
      echo "registry=$mirror" >> "$npmrc"
    fi
  else
    echo "registry=$mirror" > "$npmrc"
  fi

  log "NPM mirror configured: $mirror"
}

# ── Configure PyPI mirror ───────────────────────────────────────────────────
# Usage: _configure_pypi_mirror [region]
_configure_pypi_mirror() {
  local region="${1:-$(_detect_region)}"
  local mirror=""

  case "$region" in
    ru) mirror="$GITVERSE_PYPI_MIRROR" ;;
    cn) mirror="$CN_PYPI_MIRROR" ;;
    *)  return 0 ;;  # Use default
  esac

  info "Configuring PyPI mirror: $mirror"

  # Configure pip
  mkdir -p "$HOME/.config/pip"
  cat > "$HOME/.config/pip/pip.conf" <<EOF
[global]
index-url = $mirror
trusted-host = $(echo "$mirror" | sed 's|https://||' | sed 's|/.*||')

[install]
trusted-host = $(echo "$mirror" | sed 's|https://||' | sed 's|/.*||')
EOF

  # Configure uv (if exists)
  if command -v uv &>/dev/null; then
    mkdir -p "$HOME/.config/uv"
    cat > "$HOME/.config/uv/config.toml" <<EOF
[[index]]
url = "$mirror"
name = "gitverse"
priority = "primary"
EOF
    log "uv mirror configured"
  fi

  # Set environment variable
  export PIP_INDEX_URL="$mirror"

  log "PyPI mirror configured: $mirror"
}

# ── Configure Go mirror ─────────────────────────────────────────────────────
# Usage: _configure_go_mirror [region]
_configure_go_mirror() {
  local region="${1:-$(_detect_region)}"
  local mirror=""

  case "$region" in
    ru) mirror="$GITVERSE_GO_MIRROR" ;;
    cn) mirror="$CN_GO_MIRROR" ;;
    *)  return 0 ;;  # Use default
  esac

  info "Configuring Go mirror: $mirror"

  # Set via go env
  if command -v go &>/dev/null; then
    go env -w "GOPROXY=${mirror},direct" 2>/dev/null || true
    log "Go mirror configured: $mirror"
  fi

  # Set environment variable
  export GOPROXY="${mirror},direct"
}

# ── Configure Crates mirror ─────────────────────────────────────────────────
# Usage: _configure_crates_mirror [region]
_configure_crates_mirror() {
  local region="${1:-$(_detect_region)}"
  local mirror=""

  case "$region" in
    ru) mirror="$GITVERSE_CRATES_MIRROR" ;;
    cn) mirror="$CN_CRATES_MIRROR" ;;
    *)  return 0 ;;  # Use default
  esac

  info "Configuring Crates mirror: $mirror"

  # Configure cargo
  mkdir -p "$HOME/.cargo"
  cat > "$HOME/.cargo/config.toml" <<EOF
[source.crates-io]
replace-with = "mirror"

[source.mirror]
registry = "sparse+${mirror}/"

[net]
git-fetch-with-cli = true
retry = 3
EOF

  log "Crates mirror configured: $mirror"
}

# ── Configure Docker mirror ─────────────────────────────────────────────────
# Usage: _configure_docker_mirror [region]
_configure_docker_mirror() {
  local region="${1:-$(_detect_region)}"
  local mirror=""

  case "$region" in
    ru) mirror="$GITVERSE_DOCKER_MIRROR" ;;
    cn) mirror="$CN_DOCKER_MIRROR" ;;
    *)  return 0 ;;  # Use default
  esac

  info "Configuring Docker mirror: $mirror"

  # Detect Docker config path
  local docker_config=""
  if [ -f "/etc/docker/daemon.json" ] && [ -w "/etc/docker/daemon.json" ]; then
    docker_config="/etc/docker/daemon.json"
  elif [ -f "$HOME/.config/docker/daemon.json" ]; then
    docker_config="$HOME/.config/docker/daemon.json"
  else
    docker_config="$HOME/.config/docker/daemon.json"
    mkdir -p "$(dirname "$docker_config")"
  fi

  # Create or update daemon.json
  if [ -f "$docker_config" ]; then
    # Update existing config
    if command -v python3 &>/dev/null; then
      python3 -c "
import json, sys
try:
    with open('$docker_config', 'r') as f:
        config = json.load(f)
except:
    config = {}

if 'registry-mirrors' not in config:
    config['registry-mirrors'] = []

if '$mirror' not in config['registry-mirrors']:
    config['registry-mirrors'].append('$mirror')

with open('$docker_config', 'w') as f:
    json.dump(config, f, indent=2)
" 2>/dev/null || true
    fi
  else
    # Create new config
    cat > "$docker_config" <<EOF
{
  "registry-mirrors": ["$mirror"]
}
EOF
  fi

  # Reload Docker if running
  if command -v docker &>/dev/null && docker info &>/dev/null; then
    if command -v systemctl &>/dev/null; then
      sudo systemctl reload docker 2>/dev/null || true
    fi
    log "Docker mirror configured: $mirror"
  else
    info "Docker not running — mirror configured for next start"
  fi
}

# ── Configure all mirrors ───────────────────────────────────────────────────
# Usage: _configure_all_mirrors [--region ru|cn|global]
_configure_all_mirrors() {
  local region="${1:-$(_detect_region)}"

  section "Mirror Configuration (Region: $region)"

  _configure_npm_mirror "$region"
  _configure_pypi_mirror "$region"
  _configure_go_mirror "$region"
  _configure_crates_mirror "$region"
  _configure_docker_mirror "$region"

  log "All mirrors configured for region: $region"
}

# ── Mirror health check ─────────────────────────────────────────────────────
# Usage: _mirror_health_check
_mirror_health_check() {
  section "Mirror Health Check"

  local mirrors=(
    "NPM:$GITVERSE_NPM_MIRROR"
    "PyPI:$GITVERSE_PYPI_MIRROR"
    "Go:$GITVERSE_GO_MIRROR"
    "Crates:$GITVERSE_CRATES_MIRROR"
    "Docker:$GITVERSE_DOCKER_MIRROR"
  )

  local ok=0 fail=0

  for entry in "${mirrors[@]}"; do
    IFS=':' read -r name url <<< "$entry"
    if curl -sf --max-time 5 "$url" >/dev/null 2>&1; then
      log "  ✓ $name: $url"
      ok=$((ok + 1))
    else
      warn "  ✗ $name: $url (unreachable)"
      fail=$((fail + 1))
    fi
  done

  log "Mirror health: $ok/$((ok + fail)) reachable"
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _detect_region _configure_npm_mirror _configure_pypi_mirror \
  _configure_go_mirror _configure_crates_mirror _configure_docker_mirror \
  _configure_all_mirrors _mirror_health_check 2>/dev/null || true
