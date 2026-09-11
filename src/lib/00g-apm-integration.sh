#!/usr/bin/env bash
# src/lib/00g-apm-integration.sh — APM Integration Module (v4.0.0)
# Enables `apm install opencode_initializer` and policy-based management.
# Sources: src/lib/00-core.sh, src/lib/00f-apm.sh must be sourced before this file
set -euo pipefail

# ── APM integration configuration ────────────────────────────────────────────
_APM_POLICY="${APM_POLICY:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/apm-policy.yml}"
_APM_REGISTRY="${APM_REGISTRY:-https://registry.npmjs.org}"
_APM_PACKAGE="opencode-initializer"

# ── Generate apm-policy.yml ──────────────────────────────────────────────────
# Usage: _apm_generate_policy [output_path]
# Creates policy file for APM-managed installations.
_apm_generate_policy() {
  local output="${1:-$_APM_POLICY}"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  cat > "$output" <<EOF
# apm-policy.yml — APM installation policy for opencode-initializer
# Generated: $now

schema_version: "1.0.0"
package: "$_APM_PACKAGE"

# Installation policy
install:
  # Allowed installation methods
  methods:
    - npm
    - curl
    - git

  # Pre-install checks
  pre_checks:
    - name: "bash_version"
      description: "Bash >= 4.0 required"
      command: "bash -c '[[ \${BASH_VERSINFO[0]} -ge 4 ]]'"
      required: true

    - name: "disk_space"
      description: "At least 5GB free disk space"
      command: "df -BG ~ | awk 'NR==2 {exit \$4 < 5}'"
      required: true

    - name: "internet"
      description: "Internet connectivity"
      command: "curl -sf https://registry.npmjs.org >/dev/null 2>&1"
      required: false

  # Post-install actions
  post_actions:
    - name: "setup_path"
      description: "Add to PATH"
      command: "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"

    - name: "verify_install"
      description: "Verify installation"
      command: "opencode-init --version"

# Update policy
update:
  # Auto-update interval (hours)
  interval: 24

  # Update method
  method: "git-pull"

  # Backup before update
  backup: true

# Security policy
security:
  # Verify checksums
  verify_checksums: true

  # Allowed sources
  allowed_sources:
    - "github.com/AlexanderNarbaev/opencode_initializer"
    - "registry.npmjs.org"

  # Sandbox mode (run in Docker)
  sandbox: false

# Dependency policy
dependencies:
  # Auto-install dependencies
  auto_install: true

  # Allowed package managers
  package_managers:
    - npm
    - pip
    - cargo
    - go

  # Version pinning
  pin_versions: true
EOF

  log "APM policy generated: $output"
}

# ── APM install command ─────────────────────────────────────────────────────
# Usage: _apm_install_package
# Simulates `apm install opencode_initializer` workflow.
_apm_install_package() {
  section "APM Install: $_APM_PACKAGE"

  # Check if already installed
  if command -v opencode-init &>/dev/null; then
    local current_ver
    current_ver=$(opencode-init --version 2>/dev/null || echo "unknown")
    log "Already installed: $current_ver"
    info "Use --force to reinstall"
    return 0
  fi

  # Pre-install checks
  info "Running pre-install checks..."

  # Check bash version
  if [ "${BASH_VERSINFO[0]:-0}" -lt 4 ]; then
    warn "Bash >= 4.0 required (current: ${BASH_VERSION})"
    return 1
  fi

  # Check disk space
  local free_gb
  free_gb=$(df -BG ~ | awk 'NR==2 {print $4}' | tr -d 'G')
  if [ "${free_gb:-0}" -lt 5 ]; then
    warn "At least 5GB free disk space required (current: ${free_gb}GB)"
    return 1
  fi

  # Install via git clone
  info "Installing $_APM_PACKAGE..."
  local install_dir="$HOME/opencode_initializer"

  if [ -d "$install_dir" ]; then
    info "Directory exists, updating..."
    git -C "$install_dir" pull --ff-only -q 2>/dev/null || true
  else
    git clone --depth 1 -q "https://github.com/AlexanderNarbaev/opencode_initializer.git" "$install_dir" 2>/dev/null || {
      warn "Clone failed — check network"
      return 1
    }
  fi

  # Create symlink
  mkdir -p "$HOME/.local/bin"
  ln -sf "$install_dir/setup.sh" "$HOME/.local/bin/opencode-init" 2>/dev/null || true

  # Post-install actions
  info "Running post-install actions..."

  # Add to PATH if not already
  if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    export PATH="$HOME/.local/bin:$PATH"
  fi

  # Verify installation
  if command -v opencode-init &>/dev/null; then
    log "Installation complete"
    opencode-init --version
  else
    warn "Installation complete but opencode-init not on PATH"
    info "Add to PATH: export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
}

# ── APM update command ──────────────────────────────────────────────────────
# Usage: _apm_update_package
# Updates the installed package.
_apm_update_package() {
  section "APM Update: $_APM_PACKAGE"

  local install_dir="$HOME/opencode_initializer"

  if [ ! -d "$install_dir" ]; then
    warn "Not installed — run: apm install $_APM_PACKAGE"
    return 1
  fi

  # Backup current version
  local backup_dir="$HOME/.cache/opencode-setup/backup/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_dir"
  cp -r "$install_dir" "$backup_dir/" 2>/dev/null || true
  log "Backup created: $backup_dir"

  # Update
  info "Updating..."
  if git -C "$install_dir" pull --ff-only -q 2>/dev/null; then
    log "Update complete"
    opencode-init --version
  else
    warn "Update failed — restoring backup"
    rm -rf "$install_dir"
    cp -r "$backup_dir/opencode_initializer" "$install_dir"
    return 1
  fi
}

# ── APM uninstall command ───────────────────────────────────────────────────
# Usage: _apm_uninstall_package
# Removes the installed package.
_apm_uninstall_package() {
  section "APM Uninstall: $_APM_PACKAGE"

  local install_dir="$HOME/opencode_initializer"

  if [ ! -d "$install_dir" ]; then
    warn "Not installed"
    return 0
  fi

  # Remove symlink
  rm -f "$HOME/.local/bin/opencode-init" 2>/dev/null || true

  # Ask for confirmation
  info "This will remove: $install_dir"
  read -p "Continue? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$install_dir"
    log "Uninstalled"
  else
    info "Cancelled"
  fi
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _apm_generate_policy _apm_install_package _apm_update_package \
  _apm_uninstall_package 2>/dev/null || true
