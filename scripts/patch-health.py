#!/usr/bin/env python3
"""patch-health.py — SYNC-2 fix for src/modes/health.sh (2026-10-12).
1) JSONC-safe config parse (strip full-line // comments before json.loads)
2) $HOME/projects -> $HOME/Projects (real dir name, Linux case-sensitive)
Idempotent."""
import re
import sys

H = "/home/alexandr-narbaev/Projects/opencode_initializer/src/modes/health.sh"
s = open(H).read()
orig = s

# 1. JSONC-safe parse: json.load(open('X')) -> json.loads(''.join(l for l in open('X') if not l.lstrip().startswith('//')))
s = s.replace(
    "json.load(open('$HOME/.config/opencode/opencode.json'))",
    "json.loads(''.join(l for l in open('$HOME/.config/opencode/opencode.json') if not l.lstrip().startswith('//')))"
)
# also accept V2 keys mcp.servers / providers alongside legacy mcp/provider
s = s.replace("len(c.get('mcp',{}))", "len(c.get('mcp',{}) or (c.get('mcp',{}).get('servers',{}) if isinstance(c.get('mcp'),dict) else {}))")
s = s.replace("len(c.get('provider',{}))", "len(c.get('provider',{}) or c.get('providers',{}))")

# 2. case fix
s = s.replace("${PROJECT_DIR:-$HOME/projects}/", "${PROJECT_DIR:-$HOME/Projects}/")

changed = s != orig
open(H, "w").write(s)
print("patched" if changed else "already patched (no change)")
sys.exit(0)
