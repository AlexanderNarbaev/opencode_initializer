#!/usr/bin/env bash
# lib/51-opencode-desktop.sh — OpenCode Desktop (GUI) app (STEP 51)
# Sources: https://github.com/anomalyco/opencode (releases → opencode-desktop-*)
# Desktop GUI for the OpenCode CLI. Installs the native package (.deb/.rpm)
# or the portable AppImage. The packaged binary is a Tauri app shipped as
# /opt/OpenCode/ai.opencode.desktop (the .deb also bundles the .desktop entry,
# icon set, and an AppArmor profile via its own postinst).
set -euo pipefail

_step_skip step_opencode_desktop && return 0

# Opt-out flag (matches SKIP_DOTFILES / SKIP_DEVBOX / SKIP_GUI convention)
[ "${SKIP_DESKTOP:-false}" = "true" ] && { info "OpenCode Desktop skipped (SKIP_DESKTOP=true)"; return 0; }

section "OpenCode Desktop — GUI"

# Version pin (00-core.sh: OPENCODE_VER tracks the CLI; desktop is released in
# lockstep with the CLI in the same GitHub release). Latest resolved at install
# time via the GitHub API, falling back to the pinned default on failure.
OPENCODE_DESKTOP_VER="${OPENCODE_DESKTOP_VER:-latest}"
OCD_PINNED_VER="${OPENCODE_DESKTOP_PINNED_VER:-1.18.18}"
OCD_REPO="anomalyco/opencode"

# Installed paths (both package managers place the binary here via postinst)
OCD_BIN="/opt/OpenCode/ai.opencode.desktop"
OCD_APPDIR_BIN="$HOME/.local/share/opencode-desktop/ai.opencode.desktop"

# ── Version resolution ───────────────────────────────────────────────────────
# Resolve the latest release tag from the GitHub API (no jq dependency — sed).
# Falls back to OCD_PINNED_VER on any failure (offline / rate-limited).
_resolve_desktop_version() {
  local ver=""
  ver="$(curl -fsSL --connect-timeout 15 --max-time 30 \
    "https://api.github.com/repos/${OCD_REPO}/releases/latest" 2>/dev/null \
    | sed -n 's/^[[:space:]]*"tag_name": *"\([^"]*\)".*/\1/p' | head -1 || true)"
  [ -n "$ver" ] || ver="$OCD_PINNED_VER"
  echo "$ver"
}

# ── Asset URL builder ────────────────────────────────────────────────────────
# $1: version (e.g. v1.18.18)  $2: format (deb|rpm|AppImage)
_desktop_asset_url() {
  local ver="$1" fmt="$2"
  local arch_pkg arch_appimage
  # .deb/.rpm use the package-manager arch token (amd64/arm64); AppImage uses
  # the kernel arch token (x86_64/arm64). ARCH is normalised by 00-core.sh.
  arch_pkg="$ARCH"
  case "$ARCH" in
    amd64) arch_appimage="x86_64" ;;
    arm64) arch_appimage="arm64" ;;
    *)     arch_appimage="x86_64"; arch_pkg="amd64" ;;
  esac
  case "$fmt" in
    deb)      echo "https://github.com/${OCD_REPO}/releases/download/${ver}/opencode-desktop-linux-${arch_pkg}.deb" ;;
    rpm)      echo "https://github.com/${OCD_REPO}/releases/download/${ver}/opencode-desktop-linux-${arch_appimage}.rpm" ;;
    AppImage) echo "https://github.com/${OCD_REPO}/releases/download/${ver}/opencode-desktop-linux-${arch_appimage}.AppImage" ;;
  esac
}

# ── Desktop entry (AppImage / manual installs only — .deb/.rpm bundle theirs) ─
_write_desktop_entry() {
  local exec_path="$1"
  local entry_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  mkdir -p "$entry_dir"
  cat > "$entry_dir/opencode-desktop.desktop" << DESKTOP
[Desktop Entry]
Name=OpenCode
Comment=Open source AI coding agent (Desktop)
Exec=$exec_path %U
Terminal=false
Type=Application
Categories=Development;
StartupWMClass=ai.opencode.desktop
DESKTOP
  command -v update-desktop-database &>/dev/null && update-desktop-database "$entry_dir" 2>/dev/null || true
  log "Desktop entry written: $entry_dir/opencode-desktop.desktop"
}

# ── Installer ────────────────────────────────────────────────────────────────
_install_opencode_desktop() {
  # Already installed (package path or AppImage path)
  if [ -x "$OCD_BIN" ] || [ -x "$OCD_APPDIR_BIN" ]; then
    log "OpenCode Desktop already present"
    return 0
  fi

  local ver="$OPENCODE_DESKTOP_VER"
  if [ "$ver" = "latest" ]; then
    _spin_start "Resolving latest OpenCode Desktop version"
    ver="$(_resolve_desktop_version)"
    _spin_stop "✓"
    info "OpenCode Desktop version: $ver"
  fi

  local url deb_file
  case "${PKG_MANAGER:-}" in
    apt)
      url="$(_desktop_asset_url "$ver" deb)"
      deb_file="$DL_CACHE/opencode-desktop-${ver#v}.deb"
      _progress "OpenCode Desktop" "Downloading .deb ($ver)"
      _spin_start "Downloading opencode-desktop .deb"
      if _curl "$url" "$deb_file"; then
        _spin_stop "✓"
        _spin_start "Installing opencode-desktop (.deb)"
        if _sudo dpkg -i "$deb_file" 2>/dev/null; then
          _spin_stop "✓"
          _sudo apt-get install -f -y -qq 2>/dev/null || true
          rm -f "$deb_file"
          log "OpenCode Desktop installed (dpkg)"
          return 0
        else
          _spin_stop "✗"
          warn "dpkg install failed — try: sudo dpkg -i $deb_file"
          return 1
        fi
      else
        _spin_stop "✗"
        warn "OpenCode Desktop .deb download failed — run manually: sudo apt install ./opencode-desktop-*.deb"
        return 1
      fi
      ;;
    dnf)
      url="$(_desktop_asset_url "$ver" rpm)"
      _progress "OpenCode Desktop" "Installing .rpm ($ver)"
      _spin_start "Installing opencode-desktop (.rpm)"
      if _sudo dnf install -y -q "$url" 2>/dev/null; then
        _spin_stop "✓"
        log "OpenCode Desktop installed (dnf)"
        return 0
      fi
      _spin_stop "✗"
      warn "OpenCode Desktop .rpm install failed"
      return 1
      ;;
    *)
      # No deb/rpm package manager — fall back to the portable AppImage.
      _install_desktop_appimage "$ver"
      ;;
  esac
}

# ── AppImage fallback (no root, no deb/rpm manager) ──────────────────────────
_install_desktop_appimage() {
  local ver="$1"
  local url="$(_desktop_asset_url "$ver" AppImage)"
  local appimage="$DL_CACHE/opencode-desktop-${ver#v}.AppImage"

  _progress "OpenCode Desktop" "Installing AppImage ($ver)"
  _spin_start "Downloading opencode-desktop AppImage"
  if ! _curl "$url" "$appimage"; then
    _spin_stop "✗"
    warn "OpenCode Desktop AppImage download failed"
    return 1
  fi
  _spin_stop "✓"

  # Extract (no FUSE/libfuse.so.2 required) into a user-owned prefix.
  local dest="$HOME/.local/share/opencode-desktop"
  _spin_start "Extracting AppImage"
  mkdir -p "$dest"
  chmod +x "$appimage"
  ( cd "$dest" && "$appimage" --appimage-extract >/dev/null 2>&1 ) || true
  if [ -x "$dest/squashfs-root/ai.opencode.desktop" ]; then
    ln -sf "$dest/squashfs-root/ai.opencode.desktop" "$OCD_APPDIR_BIN" 2>/dev/null || true
    _spin_stop "✓"
    rm -f "$appimage"
    _write_desktop_entry "$OCD_APPDIR_BIN"
    log "OpenCode Desktop installed (AppImage → $dest)"
    return 0
  fi
  _spin_stop "✗"
  warn "AppImage extraction failed — run manually: $appimage --appimage-extract"
  return 1
}

# ── Configure (CLI integration + shared config) ──────────────────────────────
# The desktop app is a GUI front-end to the same OpenCode core — it reads the
# same opencode.json (model / small_model / provider) and auth.json as the CLI.
# This step wires the desktop to the CLI's config and reports the active model.
_configure_opencode_desktop() {
  # 1. CLI integration — desktop shares the CLI's core + config.
  if command -v opencode &>/dev/null; then
    log "OpenCode CLI $(opencode --version 2>/dev/null || echo 'present') — desktop shares its config"
  else
    warn "OpenCode CLI not found — desktop GUI will run, but model/provider config may be empty (install via 11-opencode.sh)"
  fi

  # 2. Shared config path (generated by 18-opencode-json.sh).
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json"
  if [ -f "$cfg" ]; then
    local model
    model="$(grep -m1 '"model"[[:space:]]*:' "$cfg" 2>/dev/null | sed -n 's/.*:[[:space:]]*"\([^"]*\)".*/\1/p' || true)"
    if [ -n "$model" ]; then
      info "OpenCode Desktop active model: $model (from $cfg)"
    else
      info "OpenCode Desktop config present: $cfg"
    fi
  else
    info "opencode.json not found at $cfg — run 'bash setup.sh --fix-config' (18-opencode-json.sh) to generate it"
  fi

  # 3. No symlink needed: both the CLI and desktop auto-discover
  #    ~/.config/opencode on first launch.
}

# ── Health check ─────────────────────────────────────────────────────────────
_check_opencode_desktop() {
  local bin=""
  [ -x "$OCD_BIN" ] && bin="$OCD_BIN"
  [ -z "$bin" ] && [ -x "$OCD_APPDIR_BIN" ] && bin="$OCD_APPDIR_BIN"
  if [ -z "$bin" ]; then
    warn "OpenCode Desktop not installed"
    return 1
  fi
  log "OpenCode Desktop binary: $bin"
  if [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    info "Display detected (${DISPLAY:-}${WAYLAND_DISPLAY:-}) — launch via app menu or: $bin"
  else
    info "No graphical display detected — OpenCode Desktop requires a desktop session"
  fi
  return 0
}

# ── Main ─────────────────────────────────────────────────────────────────────
_install_opencode_desktop || true
_configure_opencode_desktop
_check_opencode_desktop || true

_step_done step_opencode_desktop
log "OpenCode Desktop configured"
