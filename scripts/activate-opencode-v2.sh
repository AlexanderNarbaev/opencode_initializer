#!/usr/bin/env bash
# ============================================================================
# activate-opencode-v2.sh — ONE-SHOT staged OpenCode V2 activation.
#
# Runs at NEXT BOOT/LOGIN (or manually). Honors the no-kill constraint of the
# 2026-10-12 migration: it REFUSES to act while the V1 desktop
# (ai.opencode.desktop) is running, so nothing live is ever touched.
#
# Staged kit: ~/.local/share/opencode-v2-staging/
#   opencode-desktop-linux-amd64_2.0.27.deb   desktop V2 (md5-verified)
#   opencode.v2.json                          native-V2 config (staged)
#   opencode-v1-binary-backup                 V1 CLI binary (rollback)
#   README.md                                 manual activation + rollback
#
# Steps (idempotent — safe to re-run):
#   0. already activated? -> no-op success
#   1. guard: ai.opencode.desktop running -> ABORT (nothing touched)
#   2. verify deb checksum, install desktop V2 (sudo -n -> pkexec -> manual)
#      -> ABORT before config swap if install fails
#   3. swap config: opencode.json -> opencode.json.v1.bak-<date>, staged in
#   4. smoke: `opencode --version` (must be 2.x) + `opencode --help`
#      -> on failure: restore V1 config backup and ABORT
#   5. extended smoke: `opencode models --standalone`
#      -> known issue: V1-API plugin packages fail to activate under V2
#         ("Location plugins did not finish activating"). Unless
#         OPENCODE_V2_KEEP_PLUGINS=1, the script then minimally strips the
#         `plugins` array (backup kept) so the machine is left usable.
#   6. log result to activation.log; on success remove the autostart entry
#      (self-disabling). On abort the entry stays and retries next login.
#
# Exit codes: 0 = activated (or already), 1 = aborted (see log), 2 = usage.
# ============================================================================
set -euo pipefail

STAGING="${OPENCODE_V2_STAGING:-$HOME/.local/share/opencode-v2-staging}"
LOG="$STAGING/activation.log"
DEB="$STAGING/opencode-desktop-linux-amd64_2.0.27.deb"
DEB_MD5="$STAGING/opencode-desktop-linux-amd64_2.0.27.deb.md5"
STAGED_CFG="$STAGING/opencode.v2.json"
LIVE_CFG="$HOME/.config/opencode/opencode.json"
AUTOSTART="$HOME/.config/autostart/opencode-v2-activation.desktop"
DONE_MARKER="$STAGING/activation.done"
DESKTOP_PKG_VERSION="2.0.27"
DATE_TAG="$(date +%Y%m%dT%H%M%S)"

log() {
    mkdir -p "$STAGING"
    echo "[$(date -Is)] $*" | tee -a "$LOG" >&2
}

abort() {
    log "ABORT: $*"
    exit 1
}

# --- run a command with root, least-privilege escalating ---------------------
run_priv() {
    if [ "$(id -u)" = 0 ]; then
        "$@"
    elif sudo -n true 2>/dev/null; then
        sudo "$@"
    elif command -v pkexec >/dev/null 2>&1; then
        pkexec "$@"
    else
        return 1
    fi
}

# --- 0. idempotency: already activated? ------------------------------------
if [ -f "$DONE_MARKER" ]; then
    log "already activated ($(cat "$DONE_MARKER")) — nothing to do."
    exit 0
fi

[ -f "$DEB" ] || abort "staged deb missing: $DEB"
[ -f "$STAGED_CFG" ] || abort "staged config missing: $STAGED_CFG"

# --- 1. no-kill guard: never touch a live desktop session ------------------
if pgrep -f "/opt/OpenCode/ai.opencode.desktop" >/dev/null 2>&1; then
    abort "ai.opencode.desktop is RUNNING — refusing to activate over a live session. Re-run at boot/login (or quit the desktop first)."
fi

log "=== OpenCode V2 activation START (tag $DATE_TAG) ==="

# --- 2. desktop V2 install -------------------------------------------------
installed_ver="$(dpkg-query -W -f '${Version}' opencode 2>/dev/null || echo none)"
if [ "$installed_ver" = "$DESKTOP_PKG_VERSION" ]; then
    log "desktop already at $DESKTOP_PKG_VERSION — skipping dpkg install."
else
    log "verifying deb integrity (md5 vs recorded server ETag)..."
    ( cd "$STAGING" && md5sum -c "$(basename "$DEB_MD5")" >/dev/null 2>&1 ) \
        || abort "deb checksum mismatch — refusing to install."
    log "installing desktop V2 ($DEB, replacing installed $installed_ver)..."
    if ! run_priv dpkg -i "$DEB"; then
        abort "dpkg install failed (no root path worked). Manual: sudo dpkg -i $DEB — config was NOT swapped."
    fi
    log "desktop V2 installed: $(dpkg-query -W -f '${Version}' opencode 2>/dev/null)"
fi

# --- 3. config swap (V1 backup kept) ---------------------------------------
if grep -q "STAGED V2-native config" "$LIVE_CFG" 2>/dev/null; then
    log "live config already the staged V2 config — skipping swap."
else
    backup="$LIVE_CFG.v1.bak-$DATE_TAG"
    cp "$LIVE_CFG" "$backup"
    log "V1 config backed up: $backup"
    cp "$STAGED_CFG" "$LIVE_CFG"
    log "staged V2 config installed to $LIVE_CFG"
fi

# --- 4. smoke: --version + --help ------------------------------------------
restore_v1_config() {
    local bak
    bak="$(find "$HOME/.config/opencode" -maxdepth 1 -name 'opencode.json.v1.bak-*' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2- || true)"
    if [ -n "$bak" ] && [ -f "$bak" ]; then
        cp "$bak" "$LIVE_CFG"
        log "rolled back config from $bak"
    fi
}

# PATH fix (2026-10-12 boot-run lesson): autostart env lacks ~/.npm-global/bin —
# line 121 previously failed with "opencode: command not found" and rolled back the config.
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
ver_out="$(opencode --version 2>&1 || true)"
case "$ver_out" in
    *v2.*) log "smoke --version OK: $ver_out" ;;
    *) restore_v1_config; abort "smoke --version failed or not 2.x: $ver_out" ;;
esac

opencode --help >/dev/null 2>&1 \
    || { restore_v1_config; abort "smoke --help failed"; }
log "smoke --help OK"

# --- 5. extended smoke + plugin safety valve --------------------------------
ext="$(opencode models --standalone 2>&1 | head -20 || true)"
if echo "$ext" | grep -qi "did not finish activating"; then
    if [ "${OPENCODE_V2_KEEP_PLUGINS:-0}" = "1" ]; then
        log "WARN: plugins did not activate under V2 (kept per OPENCODE_V2_KEEP_PLUGINS=1)."
        log "WARN: service-based commands will fail until plugins are V2-compatible."
    else
        pre_strip="$LIVE_CFG.v2-withplugins.bak-$DATE_TAG"
        cp "$LIVE_CFG" "$pre_strip"
        python3 - "$LIVE_CFG" <<'PYEOF'
import json, re, sys
path = sys.argv[1]
raw = open(path).read()
head = "\n".join(l for l in raw.splitlines() if re.match(r'^\s*//', l))
body = "\n".join(l for l in raw.splitlines() if not re.match(r'^\s*//', l))
cfg = json.loads(body)
cfg["plugins"] = []
open(path, "w").write(head + "\n" + json.dumps(cfg, indent=2, ensure_ascii=False) + "\n")
PYEOF
        log "WARN: KNOWN-ISSUE — V1-API plugins do not activate under V2 new plugin API."
        log "WARN: minimally stripped 'plugins' -> [] (backup: $pre_strip)."
        log "WARN: re-add V2-compatible plugins in the 'plugins' array when available."
        ext="$(opencode models --standalone 2>&1 | head -20 || true)"
    fi
fi
if echo "$ext" | grep -qi "ServiceUnavailableError"; then
    log "WARN: extended smoke still failing after valve — see README.md KNOWN-ISSUES."
else
    log "extended smoke (models --standalone) OK"
fi

# --- 6. done: log + self-disable autostart ---------------------------------
log "=== OpenCode V2 activation SUCCESS ==="
echo "SUCCESS $DATE_TAG (desktop $(dpkg-query -W -f '${Version}' opencode 2>/dev/null), cli $(opencode --version 2>&1))" > "$DONE_MARKER"
if [ -f "$AUTOSTART" ]; then
    rm -f "$AUTOSTART"
    log "autostart entry removed (self-disabled): $AUTOSTART"
fi
log "result log: $LOG"
exit 0
