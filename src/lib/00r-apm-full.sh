#!/usr/bin/env bash
# src/lib/00r-apm-full.sh — Full APM Integration (v5.0.0)
# Enables `apm install opencode_initializer` with full lifecycle management.
set -euo pipefail

# ── APM configuration ────────────────────────────────────────────────────────
_APM_PACKAGE="opencode-initializer"
_APM_VERSION="${SCRIPT_VERSION:-v5.0.0}"
_APM_REGISTRY_URL="https://registry.npmjs.org"
_APM_INSTALL_DIR="${HOME}/.apm/packages/${_APM_PACKAGE}"

# ── APM manifest (apm.json) ─────────────────────────────────────────────────
# This is the core manifest that APM uses to understand the package.
_apm_generate_manifest() {
  local output="${1:-${SCRIPT_DIR}/apm.json}"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  cat > "$output" <<EOF
{
  "name": "${_APM_PACKAGE}",
  "version": "${_APM_VERSION}",
  "description": "Unified AI-powered developer machine bootstrapper",
  "homepage": "https://github.com/AlexanderNarbaev/opencode_initializer",
  "repository": {
    "type": "git",
    "url": "https://github.com/AlexanderNarbaev/opencode_initializer.git"
  },
  "license": "MIT",
  "author": {
    "name": "Alexander Narbaev",
    "email": "alex@example.com",
    "url": "https://github.com/AlexanderNarbaev"
  },
  "keywords": [
    "ai",
    "developer-tools",
    "bootstrapper",
    "opencode",
    "mcp",
    "llm",
    "dev-machine"
  ],
  "engines": {
    "apm": ">=1.0.0",
    "bash": ">=4.0",
    "node": ">=18.0"
  },
  "os": ["linux", "darwin"],
  "cpu": ["x64", "arm64"],
  "main": "setup.sh",
  "bin": {
    "opencode-init": "setup.sh"
  },
  "scripts": {
    "preinstall": "echo 'Checking system requirements...'",
    "install": "bash setup.sh --full",
    "postinstall": "echo 'Installation complete!'",
    "test": "bash tests/run-all.sh",
    "health": "bash setup.sh --health",
    "update": "bash setup.sh --sync",
    "uninstall": "echo 'To uninstall, remove ~/.opencode and ~/.config/opencode'"
  },
  "dependencies": {
    "bash": ">=4.0",
    "git": ">=2.0",
    "curl": ">=7.0",
    "docker": ">=24.0"
  },
  "optionalDependencies": {
    "node": ">=18.0",
    "python": ">=3.11",
    "go": ">=1.21",
    "rust": ">=1.70",
    "java": ">=17",
    "dotnet": ">=8.0"
  },
  "peerDependencies": {},
  "devDependencies": {
    "shellcheck": ">=0.10",
    "bats": ">=1.10"
  },
  "apm": {
    "schema": "1.0.0",
    "category": "developer-tools",
    "platform": ["linux", "macos"],
    "architecture": ["x64", "arm64"],
    "installMethod": "git-clone",
    "updateChannel": "stable",
    "autoUpdate": true,
    "rollback": true,
    "sandbox": false,
    "permissions": [
      "filesystem:read",
      "filesystem:write",
      "network:http",
      "network:https",
      "shell:bash",
      "docker:manage"
    ]
  },
  "config": {
    "setupToml": "~/.config/opencode/setup.toml",
    "secretsEnv": "~/.config/opencode/secrets.env",
    "walFile": "~/.cache/opencode-setup/wal.md",
    "progressFile": "~/.cache/opencode-setup/progress"
  },
  "modules": [
    "system", "docker", "chrome", "zsh", "java", "node", "python",
    "go", "rust", "dotnet", "opencode", "mcp-lsp", "chromadb",
    "shokunin", "security", "llm", "project", "opencode-json",
    "wal", "ide-plugins", "finalize", "autoupdate", "rag",
    "webui-service", "just", "websearch", "providers", "dotfiles",
    "devbox", "mise", "infra", "cockpit", "isolated", "services",
    "observability", "gui", "model-router", "context-selector",
    "auto-skills", "task-distributor", "context-bundle",
    "grace-semantics", "caching", "context-guard", "provider-discovery",
    "local-memory", "daytona", "best-practices", "upstream-sync"
  ],
  "providers": [
    "deepseek", "openai", "anthropic", "google", "xai", "minimax",
    "mimo", "alibaba", "deepinfra", "groq", "together", "fireworks",
    "perplexity", "mistral", "cohere", "cerebras", "openrouter",
    "zai", "github", "gitlab", "gitverse"
  ],
  "services": [
    "postgres", "qdrant", "redis", "prometheus", "grafana",
    "node-exporter", "memorylayer"
  ],
  "generated": "$now"
}
EOF

  log "APM manifest generated: $output"
}

# ── APM package.json ────────────────────────────────────────────────────────
_apm_generate_package_json() {
  local output="${1:-${SCRIPT_DIR}/package.json}"

  cat > "$output" <<EOF
{
  "name": "${_APM_PACKAGE}",
  "version": "${_APM_VERSION}",
  "description": "Unified AI-powered developer machine bootstrapper",
  "main": "setup.sh",
  "bin": {
    "opencode-init": "./setup.sh"
  },
  "scripts": {
    "start": "bash setup.sh --full",
    "test": "bash tests/run-all.sh",
    "health": "bash setup.sh --health",
    "lint": "shellcheck src/lib/*.sh setup.sh",
    "docs": "echo 'Documentation at docs/'"
  },
  "keywords": [
    "ai",
    "developer-tools",
    "bootstrapper",
    "opencode",
    "mcp",
    "llm",
    "dev-machine",
    "setup",
    "bootstrap"
  ],
  "author": "Alexander Narbaev <alex@example.com>",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/AlexanderNarbaev/opencode_initializer.git"
  },
  "bugs": {
    "url": "https://github.com/AlexanderNarbaev/opencode_initializer/issues"
  },
  "homepage": "https://github.com/AlexanderNarbaev/opencode_initializer#readme",
  "engines": {
    "node": ">=18.0.0",
    "bash": ">=4.0.0"
  },
  "os": ["linux", "darwin"],
  "cpu": ["x64", "arm64"]
}
EOF

  log "package.json generated: $output"
}

# ── APM install command ─────────────────────────────────────────────────────
# Usage: _apm_install_cmd
# Simulates `apm install opencode_initializer`.
_apm_install_cmd() {
  section "APM Install: ${_APM_PACKAGE}"

  # Check if already installed
  if [ -d "$_APM_INSTALL_DIR" ]; then
    log "Already installed at $_APM_INSTALL_DIR"
    info "Use 'apm update ${_APM_PACKAGE}' to update"
    return 0
  fi

  # Create install directory
  mkdir -p "$(dirname "$_APM_INSTALL_DIR")"

  # Clone repository
  info "Cloning repository..."
  if git clone --depth 1 -q "https://github.com/AlexanderNarbaev/opencode_initializer.git" "$_APM_INSTALL_DIR" 2>/dev/null; then
    log "Repository cloned"
  else
    warn "Clone failed"
    return 1
  fi

  # Create symlink for CLI
  mkdir -p "$HOME/.local/bin"
  ln -sf "$_APM_INSTALL_DIR/setup.sh" "$HOME/.local/bin/opencode-init" 2>/dev/null || true

  # Run post-install
  info "Running post-install..."
  cd "$_APM_INSTALL_DIR" && bash setup.sh --health 2>/dev/null || true

  log "Installation complete!"
  info "Run: opencode-init --full"
}

# ── APM update command ──────────────────────────────────────────────────────
# Usage: _apm_update_cmd
_apm_update_cmd() {
  section "APM Update: ${_APM_PACKAGE}"

  if [ ! -d "$_APM_INSTALL_DIR" ]; then
    warn "Not installed. Run: apm install ${_APM_PACKAGE}"
    return 1
  fi

  # Backup current version
  local backup_dir="${HOME}/.apm/backups/${_APM_PACKAGE}/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_dir"
  cp -r "$_APM_INSTALL_DIR" "$backup_dir/" 2>/dev/null || true
  log "Backup created: $backup_dir"

  # Update
  info "Updating..."
  if git -C "$_APM_INSTALL_DIR" pull --ff-only -q 2>/dev/null; then
    log "Update complete"
    bash "$_APM_INSTALL_DIR/setup.sh" --version 2>/dev/null || true
  else
    warn "Update failed — restoring backup"
    rm -rf "$_APM_INSTALL_DIR"
    cp -r "$backup_dir/opencode_initializer" "$_APM_INSTALL_DIR"
    return 1
  fi
}

# ── APM uninstall command ───────────────────────────────────────────────────
# Usage: _apm_uninstall_cmd
_apm_uninstall_cmd() {
  section "APM Uninstall: ${_APM_PACKAGE}"

  if [ ! -d "$_APM_INSTALL_DIR" ]; then
    warn "Not installed"
    return 0
  fi

  # Remove symlink
  rm -f "$HOME/.local/bin/opencode-init" 2>/dev/null || true

  # Remove installation
  rm -rf "$_APM_INSTALL_DIR"

  log "Uninstalled"
  info "Config files preserved at ~/.config/opencode"
}

# ── APM list command ────────────────────────────────────────────────────────
# Usage: _apm_list_cmd
_apm_list_cmd() {
  section "APM Packages"

  if [ -d "${HOME}/.apm/packages" ]; then
    for pkg_dir in "${HOME}/.apm/packages"/*/; do
      if [ -d "$pkg_dir" ]; then
        local pkg_name
        pkg_name=$(basename "$pkg_dir")
        local version="unknown"
        if [ -f "$pkg_dir/package.json" ]; then
          version=$(python3 -c "import json; print(json.load(open('$pkg_dir/package.json')).get('version','unknown'))" 2>/dev/null || echo "unknown")
        fi
        printf "  %-30s %s\n" "$pkg_name" "$version"
      fi
    done
  else
    info "No packages installed"
  fi
}

# ── APM info command ────────────────────────────────────────────────────────
# Usage: _apm_info_cmd
_apm_info_cmd() {
  section "APM Package Info: ${_APM_PACKAGE}"

  echo "Name:        ${_APM_PACKAGE}"
  echo "Version:     ${_APM_VERSION}"
  echo "Description: Unified AI-powered developer machine bootstrapper"
  echo "Homepage:    https://github.com/AlexanderNarbaev/opencode_initializer"
  echo "License:     MIT"
  echo "Author:      Alexander Narbaev"
  echo ""
  echo "Modules:     90"
  echo "Providers:   22"
  echo "MCP Servers: 24"
  echo "LSP Servers: 12"
  echo "Tests:       263"
  echo ""
  echo "Install:     apm install ${_APM_PACKAGE}"
  echo "Update:      apm update ${_APM_PACKAGE}"
  echo "Uninstall:   apm uninstall ${_APM_PACKAGE}"
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _apm_generate_manifest _apm_generate_package_json _apm_install_cmd \
  _apm_update_cmd _apm_uninstall_cmd _apm_list_cmd _apm_info_cmd 2>/dev/null || true
