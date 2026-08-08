#!/usr/bin/env bash
# migration: 20260808-v2.0.2-remove-moonshot — cleanup Moonshot/Kimi + LiteLLM leftovers from v2.0.1
# Idempotent: safe to run multiple times. Marker set by dev.sh runner ($DL_CACHE/.mig-<ts>).
#
# Rationale: wave v2.0.2 removed Moonshot/LiteLLM from the repository (modules, scripts, configs),
# but machines that ran v2.0.1 still have: kimi-proxy/litellm systemd user services,
# pipx-installed litellm, ~/.local/share/kimi-proxy/, MOONSHOT_API_KEY in configs,
# and stale opencode.json with moonshot provider.
set -euo pipefail

# ── Stop & disable systemd user services ──────────────────────────────────────
for svc in kimi-proxy litellm; do
  if systemctl --user is-enabled "$svc.service" &>/dev/null 2>&1; then
    systemctl --user stop "$svc.service" 2>/dev/null || true
    systemctl --user disable "$svc.service" 2>/dev/null || true
    echo "[migrate] Stopped & disabled: $svc.service"
  fi
done

# ── Remove stale systemd unit files (if they survived) ────────────────────────
for svc_file in \
  "$HOME/.config/systemd/user/kimi-proxy.service" \
  "$HOME/.config/systemd/user/litellm.service"; do
  if [ -f "$svc_file" ]; then
    rm -f "$svc_file"
    echo "[migrate] Removed unit file: $svc_file"
  fi
done

# Reload systemd user daemon to pick up removed units
systemctl --user daemon-reload 2>/dev/null || true

# ── Uninstall litellm from pipx ───────────────────────────────────────────────
if command -v pipx &>/dev/null && pipx list 2>/dev/null | grep -q litellm; then
  pipx uninstall litellm 2>/dev/null && echo "[migrate] pipx uninstall litellm OK" || true
fi

# ── Remove kimi-proxy runtime directory ───────────────────────────────────────
if [ -d "$HOME/.local/share/kimi-proxy" ]; then
  rm -rf "$HOME/.local/share/kimi-proxy"
  echo "[migrate] Removed: ~/.local/share/kimi-proxy"
fi

# ── Remove stale Litellm config (if any) ─────────────────────────────────────
if [ -d "$HOME/.config/litellm" ]; then
  rm -rf "$HOME/.config/litellm"
  echo "[migrate] Removed: ~/.config/litellm"
fi

# ── Clean MOONSHOT_API_KEY (and KIMI_*) from setup.conf ───────────────────────
CONFIG_FILE="$HOME/.config/opencode-setup/setup.conf"
if [ -f "$CONFIG_FILE" ]; then
  if grep -qE '^(MOONSHOT|KIMI)_' "$CONFIG_FILE" 2>/dev/null; then
    # Backup before modification
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak-$(date +%Y%m%d-%H%M%S)"
    # Remove all MOONSHOT_* and KIMI_* env lines
    sed -i '/^MOONSHOT_/d; /^KIMI_/d' "$CONFIG_FILE"
    echo "[migrate] Removed MOONSHOT_*/KIMI_* entries from setup.conf (backup saved)"
  fi
fi

# ── Regenerate opencode.json (removes moonshot provider, fixes fallback chains) ─
OP="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "$OP/setup.sh" ]; then
  bash "$OP/setup.sh" --fix-config 2>/dev/null && echo "[migrate] opencode.json regenerated" || echo "[migrate] WARNING: opencode.json regeneration failed (ignore if setup.sh not runnable)"
fi

echo "[migrate] Migration 20260808-v2.0.2-remove-moonshot complete"
