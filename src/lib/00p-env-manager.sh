#!/usr/bin/env bash
# src/lib/00p-env-manager.sh — Environment Manager (v4.5.0)
# Manages multiple development environments (personal, work, client, etc.)
set -euo pipefail

# ── Environment configuration ────────────────────────────────────────────────
_ENV_DIR="${HOME}/.config/opencode-envs"
_ENV_CURRENT="${_ENV_DIR}/current.env"
_ENV_REGISTRY="${_ENV_DIR}/registry.json"

# ── Initialize environment manager ──────────────────────────────────────────
_env_init() {
  mkdir -p "$_ENV_DIR"
  
  if [ ! -f "$_ENV_REGISTRY" ]; then
    cat > "$_ENV_REGISTRY" <<'EOF'
{
  "version": "1.0.0",
  "environments": {
    "default": {
      "description": "Default personal environment",
      "created": "2026-01-01T00:00:00Z",
      "active": true
    }
  },
  "current": "default"
}
EOF
  fi
}

# ── Create new environment ──────────────────────────────────────────────────
# Usage: _env_create "work" "Work environment with corporate settings"
_env_create() {
  local name="$1" description="${2:-}"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  _env_init

  local env_file="$_ENV_DIR/${name}.env"
  
  if [ -f "$env_file" ]; then
    warn "Environment already exists: $name"
    return 1
  fi

  # Create environment file
  cat > "$env_file" <<EOF
# Environment: $name
# Created: $now
# Description: $description

# Git configuration
GIT_NAME="${GIT_NAME:-$(git config --global user.name 2>/dev/null || echo '')}"
GIT_EMAIL="${GIT_EMAIL:-$(git config --global user.email 2>/dev/null || echo '')}"

# API keys (add your keys here)
# DEEPSEEK_KEY=
# OPENAI_API_KEY=
# ANTHROPIC_API_KEY=

# Project directory
PROJECT_DIR="${PROJECT_DIR:-$HOME/projects}"

# Shell preferences
SHELL_PREFERENCE="${SHELL_PREFERENCE:-zsh}"

# Provider preferences
DEFAULT_PROVIDER="${DEFAULT_PROVIDER:-deepseek}"
DEFAULT_MODEL="${DEFAULT_MODEL:-deepseek-chat}"

# Infrastructure
DOCKER_PREFERRED="${DOCKER_PREFERRED:-true}"
INFRA_SERVICES="${INFRA_SERVICES:-postgres redis}"
EOF

  # Update registry
  python3 -c "
import json, sys
with open('$_ENV_REGISTRY', 'r') as f:
    data = json.load(f)

data['environments']['$name'] = {
    'description': '$description',
    'created': '$now',
    'active': False
}

with open('$_ENV_REGISTRY', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true

  log "Environment created: $name"
  info "Edit: $env_file"
}

# ── Switch environment ──────────────────────────────────────────────────────
# Usage: _env_switch "work"
_env_switch() {
  local name="$1"

  _env_init

  local env_file="$_ENV_DIR/${name}.env"
  
  if [ ! -f "$env_file" ]; then
    warn "Environment not found: $name"
    return 1
  fi

  # Copy to current
  cp "$env_file" "$_ENV_CURRENT"

  # Update registry
  python3 -c "
import json, sys
with open('$_ENV_REGISTRY', 'r') as f:
    data = json.load(f)

# Deactivate all
for env in data['environments'].values():
    env['active'] = False

# Activate selected
if '$name' in data['environments']:
    data['environments']['$name']['active'] = True

data['current'] = '$name'

with open('$_ENV_REGISTRY', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true

  log "Switched to environment: $name"
}

# ── List environments ───────────────────────────────────────────────────────
# Usage: _env_list
_env_list() {
  _env_init

  section "Environments"

  python3 -c "
import json, sys
with open('$_ENV_REGISTRY', 'r') as f:
    data = json.load(f)

current = data.get('current', 'default')

for name, info in data.get('environments', {}).items():
    active = '→' if name == current else ' '
    desc = info.get('description', '')[:40]
    print(f'{active} {name:20} {desc}')
" 2>/dev/null || true
}

# ── Show environment ────────────────────────────────────────────────────────
# Usage: _env_show "work"
_env_show() {
  local name="${1:-current}"

  _env_init

  local env_file
  if [ "$name" = "current" ]; then
    env_file="$_ENV_CURRENT"
  else
    env_file="$_ENV_DIR/${name}.env"
  fi

  if [ ! -f "$env_file" ]; then
    warn "Environment not found: $name"
    return 1
  fi

  section "Environment: $name"
  cat "$env_file"
}

# ── Delete environment ──────────────────────────────────────────────────────
# Usage: _env_delete "work"
_env_delete() {
  local name="$1"

  if [ "$name" = "default" ]; then
    warn "Cannot delete default environment"
    return 1
  fi

  _env_init

  local env_file="$_ENV_DIR/${name}.env"
  
  if [ ! -f "$env_file" ]; then
    warn "Environment not found: $name"
    return 1
  fi

  rm -f "$env_file"

  # Update registry
  python3 -c "
import json, sys
with open('$_ENV_REGISTRY', 'r') as f:
    data = json.load(f)

if '$name' in data['environments']:
    del data['environments']['$name']

if data.get('current') == '$name':
    data['current'] = 'default'

with open('$_ENV_REGISTRY', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true

  log "Environment deleted: $name"
}

# ── Export environment ──────────────────────────────────────────────────────
# Usage: _env_export "work" "/path/to/backup"
_env_export() {
  local name="$1" dest="${2:-.}"

  _env_init

  local env_file="$_ENV_DIR/${name}.env"
  
  if [ ! -f "$env_file" ]; then
    warn "Environment not found: $name"
    return 1
  fi

  local export_file="${dest}/${name}.env.$(date +%Y%m%d).tar.gz"
  
  tar -czf "$export_file" -C "$_ENV_DIR" "${name}.env" 2>/dev/null || true
  
  log "Environment exported: $export_file"
}

# ── Import environment ──────────────────────────────────────────────────────
# Usage: _env_import "/path/to/work.env.20260101.tar.gz"
_env_import() {
  local archive="$1"

  if [ ! -f "$archive" ]; then
    warn "Archive not found: $archive"
    return 1
  fi

  _env_init

  tar -xzf "$archive" -C "$_ENV_DIR" 2>/dev/null || true
  
  local name
  name=$(basename "$archive" | cut -d. -f1)
  
  log "Environment imported: $name"
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _env_init _env_create _env_switch _env_list _env_show \
  _env_delete _env_export _env_import 2>/dev/null || true
