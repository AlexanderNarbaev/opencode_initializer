#!/usr/bin/env bash
# modes/fix-zshrc.sh — fix zshrc mode (dedup, fix quotes, P10k compat)
# Sources: lib/helpers.sh must be sourced before
set -euo pipefail

section "Repairing ~/.zshrc"
python3 << 'PYFIX'
import os, re
zshrc = os.path.expanduser("~/.zshrc")
with open(zshrc) as f:
    content = f.read()
original = content

# Fix unmatched quotes — add missing closing " on PATH lines
lines = content.split('\n')
fixed_lines = []
for line in lines:
    stripped = line.strip()
    if stripped.startswith('export PATH="') and not stripped.rstrip().endswith('"'):
        if stripped.count('"') % 2 == 1:
            line = line.rstrip() + '"'
    fixed_lines.append(line)
content = '\n'.join(fixed_lines)

# Remove duplicate BUN_INSTALL blocks (keep first occurrence)
content = re.sub(r'(# bun\nexport BUN_INSTALL="\$HOME/\.bun"\nexport PATH="\$BUN_INSTALL/bin:\$PATH"\n)+',
                 '# bun\nexport BUN_INSTALL="$HOME/.bun"\nexport PATH="$BUN_INSTALL/bin:$PATH"\n',
                 content)

# Remove all duplicate OPENCODE_API_KEY and OPENCODE_GO_API_KEY blocks — keep only last set
lines = content.split('\n')
seen_keys = set()
deduped = []
for line in reversed(lines):
    if 'OPENCODE_API_KEY=' in line or 'OPENCODE_GO_API_KEY=' in line:
        key = line.split('=')[0].strip().replace('export ', '')
        if key in seen_keys:
            continue
        seen_keys.add(key)
    deduped.append(line)
content = '\n'.join(reversed(deduped))

# Remove duplicate PATH exports — keep only first CORE_PATH style line
lines = content.split('\n')
seen_path = False
deduped = []
for line in lines:
    if 'export PATH="$HOME/.npm-global/bin' in line or 'export PATH="$NPM_GLOBAL' in line:
        if not seen_path:
            deduped.append(line)
            seen_path = True
        continue
    deduped.append(line)
content = '\n'.join(deduped)

# Ensure single clean PATH line exists
CORE_PATH_LINE = 'export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/.n/bin:$HOME/.bun/bin:$HOME/.cargo/bin:$HOME/.jbang/bin:/usr/local/go/bin:$PATH"'
if CORE_PATH_LINE not in content:
    content = content.rstrip() + '\n' + CORE_PATH_LINE + '\n'

# Fix shokunin profile source — redirect/disable console echo to prevent P10k warning
content = content.replace(
    '[ -f "$HOME/.shokunin/scripts/linux/profile.sh" ] && source "$HOME/.shokunin/scripts/linux/profile.sh"',
    '[ -f "$HOME/.shokunin/scripts/linux/profile.sh" ] && source "$HOME/.shokunin/scripts/linux/profile.sh" 2>/dev/null'
)

if content != original:
    with open(zshrc, 'w') as f:
        f.write(content)
    print("FIXED: ~/.zshrc repaired (dedup, quotes, P10k compat)")
else:
    print("OK: ~/.zshrc already clean")
PYFIX

# Fix shokunin profile.sh — suppress console echo
SHOKUNIN_PROFILE="$HOME/.shokunin/scripts/linux/profile.sh"
if [ -f "$SHOKUNIN_PROFILE" ]; then
  if grep -q 'echo "Shokunin AI Ecosystem loaded"' "$SHOKUNIN_PROFILE" 2>/dev/null; then
    sed -i 's/echo "Shokunin AI Ecosystem loaded"/# echo "Shokunin AI Ecosystem loaded"/' "$SHOKUNIN_PROFILE" 2>/dev/null || true
    log "Shokunin profile.sh: disabled console echo (P10k compat)"
  fi
fi

# Fix P10k instant prompt — set to quiet
P10K_FILE="$HOME/.p10k.zsh"
if [ -f "$P10K_FILE" ]; then
  sed -i 's/POWERLEVEL9K_INSTANT_PROMPT=verbose/POWERLEVEL9K_INSTANT_PROMPT=quiet/' "$P10K_FILE" 2>/dev/null || true
  log "P10k instant prompt: verbose → quiet"
fi

log "~/.zshrc repair complete"
exit 0
