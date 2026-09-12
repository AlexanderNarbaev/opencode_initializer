#!/usr/bin/env bash
# src/lib/00w-shell-integrations.sh — Shell tool integrations
# atuin, zoxide, starship
set -euo pipefail

# ── atuin integration ────────────────────────────────────────────────────────
# https://github.com/atuinsh/atuin

_atuin_install() {
  if command -v atuin &>/dev/null; then
    log "atuin already installed"
    return 0
  fi

  info "Installing atuin..."
  curl -sSL https://raw.githubusercontent.com/atuinsh/atuin/main/install.sh | bash 2>/dev/null || {
    warn "atuin installation failed"
    return 1
  }

  log "atuin installed"
}

_atuin_configure() {
  local shell_rc="$1"

  if ! command -v atuin &>/dev/null; then
    return 0
  fi

  # Add to shell rc if not present
  if ! grep -q "atuin init" "$shell_rc" 2>/dev/null; then
    echo '' >> "$shell_rc"
    echo '# atuin - magical shell history' >> "$shell_rc"
    echo 'eval "$(atuin init bash)"' >> "$shell_rc"
    log "atuin added to $shell_rc"
  fi
}

# ── zoxide integration ───────────────────────────────────────────────────────
# https://github.com/ajeetdsouza/zoxide

_zoxide_install() {
  if command -v zoxide &>/dev/null; then
    log "zoxide already installed"
    return 0
  fi

  info "Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh 2>/dev/null || {
    warn "zoxide installation failed"
    return 1
  }

  log "zoxide installed"
}

_zoxide_configure() {
  local shell_rc="$1"

  if ! command -v zoxide &>/dev/null; then
    return 0
  fi

  # Add to shell rc if not present
  if ! grep -q "zoxide init" "$shell_rc" 2>/dev/null; then
    echo '' >> "$shell_rc"
    echo '# zoxide - smarter cd command' >> "$shell_rc"
    echo 'eval "$(zoxide init bash)"' >> "$shell_rc"
    echo 'alias cd="z"' >> "$shell_rc"
    log "zoxide added to $shell_rc"
  fi
}

# ── starship integration ─────────────────────────────────────────────────────
# https://starship.rs

_starship_install() {
  if command -v starship &>/dev/null; then
    log "starship already installed"
    return 0
  fi

  info "Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y 2>/dev/null || {
    warn "starship installation failed"
    return 1
  }

  log "starship installed"
}

_starship_configure() {
  local shell_rc="$1"

  if ! command -v starship &>/dev/null; then
    return 0
  fi

  # Add to shell rc if not present
  if ! grep -q "starship init" "$shell_rc" 2>/dev/null; then
    echo '' >> "$shell_rc"
    echo '# starship - cross-shell prompt' >> "$shell_rc"
    echo 'eval "$(starship init bash)"' >> "$shell_rc"
    log "starship added to $shell_rc"
  fi

  # Create config if not exists
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
  local config_file="$config_dir/starship.toml"

  if [ ! -f "$config_file" ]; then
    mkdir -p "$config_dir"
    cat > "$config_file" << 'EOF'
# Starship configuration
# https://starship.rs/config/

format = """
$username\
$hostname\
$directory\
$git_branch\
$git_status\
$python\
$nodejs\
$rust\
$golang\
$java\
$docker_context\
$cmd_duration\
$line_break\
$character"""

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"

[directory]
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = " "
format = "on [$symbol$branch]($style) "

[git_status]
format = '([$all_status$ahead_behind]($style) )'

[python]
symbol = " "
format = "via [$symbol$version]($style) "

[nodejs]
symbol = " "
format = "via [$symbol$version]($style) "

[rust]
symbol = " "
format = "via [$symbol$version]($style) "

[golang]
symbol = " "
format = "via [$symbol$version] ($style)"

[java]
symbol = " "
format = "via [$symbol$version]($style) "

[docker_context]
symbol = " "
format = "via [$symbol$context]($style) "

[cmd_duration]
min_time = 2_000
format = "took [$duration]($style) "
EOF
    log "Starship config created: $config_file"
  fi
}

# ── Install all shell integrations ──────────────────────────────────────────
# Usage: _shell_integrations_install [SHELL_RC]
_shell_integrations_install() {
  local shell_rc="${1:-$HOME/.bashrc}"

  section "Shell Integrations"

  _atuin_install
  _atuin_configure "$shell_rc"

  _zoxide_install
  _zoxide_configure "$shell_rc"

  _starship_install
  _starship_configure "$shell_rc"

  log "Shell integrations configured"
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _atuin_install _atuin_configure _zoxide_install _zoxide_configure \
  _starship_install _starship_configure _shell_integrations_install 2>/dev/null || true
