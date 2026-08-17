#!/usr/bin/env bash
# Debug: replicate run_isolated for "configure reads model from config"
set -uo pipefail
MOD="/home/alexandr-narbaev/Projects/opencode_initializer/src/lib/51-opencode-desktop.sh"
TESTHOME="$(mktemp -d /tmp/ocd-debug.XXXXXX)"

log(){ :; }; warn(){ :; }; info(){ echo "$*"; }; err(){ :; }; section(){ :; }
_progress(){ :; }; _spin_start(){ :; }; _spin_stop(){ :; }
_step_skip(){ return 1; }; _step_done(){ :; }
opencode(){ echo '1.17.0'; }
export HOME="$TESTHOME" ARCH=amd64 PKG_MANAGER=apt DL_CACHE="$TESTHOME/dl"
mkdir -p "$HOME/.local/share/opencode-desktop"
touch "$HOME/.local/share/opencode-desktop/ai.opencode.desktop"
chmod +x "$HOME/.local/share/opencode-desktop/ai.opencode.desktop"
mkdir -p "$HOME/.config/opencode"
printf '{\n  "model": "deepseek/deepseek-v4-pro"\n}\n' > "$HOME/.config/opencode/opencode.json"

echo "=== config file content (cat -A) ==="
cat -A "$HOME/.config/opencode/opencode.json"

echo "=== source module ==="
source "$MOD"
echo "source exit: $?"

echo "=== XDG_CONFIG_HOME is [${XDG_CONFIG_HOME:-UNSET}] ==="

echo "=== direct _configure_opencode_desktop output ==="
_configure_opencode_desktop
echo "function exit: $?"

echo "=== check: model extraction ==="
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json"
model="$(grep -m1 '"model"[[:space:]]*:' "$cfg" 2>/dev/null | sed -n 's/.*:[[:space:]]*"\([^"]*\)".*/\1/p' || true)"
echo "extracted model=[$model]"

echo "=== check: grep -q here-string ==="
o="$(_configure_opencode_desktop 2>&1)"
echo "o=[$o]"
grep -q 'deepseek/deepseek-v4-pro' <<< "$o"
echo "grep exit: $?"
