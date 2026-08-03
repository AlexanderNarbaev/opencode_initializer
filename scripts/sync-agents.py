#!/usr/bin/env python3
"""
Remove Kimi proxy sections from AGENTS.md files.
"""
import os, re, glob

PROJECTS_DIR = '/home/alexandr-narbaev/Projects'

for agents_file in sorted(glob.glob(f"{PROJECTS_DIR}/*/AGENTS.md")):
    proj = os.path.basename(os.path.dirname(agents_file))
    with open(agents_file) as f:
        content = f.read()
    new_content = re.sub(r'\n## Kimi/Moonshot Proxy.*?(?=\n## |\n---|\Z)', '', content, flags=re.DOTALL)
    if new_content != content:
        with open(agents_file, 'w') as f:
            f.write(new_content)
        print(f"[{proj}] Kimi section removed")
    else:
        print(f"[{proj}] nothing to remove")

print("\nDone")
