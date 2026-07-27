#!/usr/bin/env python3
"""
Add Kimi proxy section to AGENTS.md files that don't have it.
"""
import os
import glob

KIMI_SECTION = """
## Kimi/Moonshot Proxy

- **Proxy:** kimi-proxy v14.2 (`http://127.0.0.1:9876/v1`)
- **Models:** `moonshotai/kimi-k3`, `moonshotai/kimi-k2.7-code`
- **VPN required** for stable connections to api.moonshot.ai
- **20KB limit:** proxy auto-compresses payloads (sticky tools: bash/read/write/edit/grep/glob)
- **Status:** `systemctl --user status kimi-proxy`
- **Config:** `KIMI_PROXY_MAX_TOOLS`, `KIMI_PROXY_MAX_MSGS`, `KIMI_PROXY_MAX_MSG_CONTENT` (env vars)
"""

PROJECTS_DIR = '/home/alexandr-narbaev/Projects'

for agents_file in sorted(glob.glob(f"{PROJECTS_DIR}/*/AGENTS.md")):
    proj = os.path.basename(os.path.dirname(agents_file))
    
    with open(agents_file) as f:
        content = f.read()
    
    if 'kimi' in content.lower() or 'moonshot' in content.lower():
        print(f"[{proj}] SKIP (already has Kimi section)")
        continue
    
    # Add at the end
    with open(agents_file, 'a') as f:
        f.write(KIMI_SECTION)
    
    print(f"[{proj}] + Kimi proxy section added")

print("\nDone")
