#!/usr/bin/env python3
"""
Distribute opencode_initializer's provider config to all projects.

Ensures all projects have:
- mimo, minimax providers
- Correct base_url format (options.baseURL, not base_url)
- Consistent model defaults
"""
import json
import os
import glob
import sys
import shutil

REFERENCE = '/home/alexandr-narbaev/Projects/opencode_initializer/opencode.json'
PROJECTS_DIR = '/home/alexandr-narbaev/Projects'

# Provider config from opencode_initializer (the canonical version)
MIMO_PROVIDER = {
    "options": {
        "timeout": 600000,
        "chunkTimeout": 60000,
        "setCacheKey": True
    },
    "fallback": ["deepseek", "opencode"]
}

MINIMAX_PROVIDER = {
    "options": {
        "timeout": 600000,
        "chunkTimeout": 60000,
        "setCacheKey": True,
        "baseURL": "https://api.minimax.io/v1",
        "apiKey": "{env:MINIMAX_API_KEY}"
    },
    "fallback": ["deepseek", "opencode"]
}


def clean_provider_config(provider_data):
    """Remove stale base_url/api_key keys that conflict with options.baseURL."""
    if isinstance(provider_data, dict):
        provider_data.pop("base_url", None)
        provider_data.pop("api_key", None)
    return provider_data


def update_project_config(config_path):
    """Update a single project's opencode.json with canonical provider config."""
    try:
        with open(config_path) as f:
            config = json.load(f)
    except Exception as e:
        print(f"  ERROR reading: {e}")
        return False

    providers = config.get("provider", {})
    changed = False

    # Update mimo provider
    if "mimo" not in providers:
        providers["mimo"] = MIMO_PROVIDER.copy()
        changed = True
        print("  + mimo added")

    # Update minimax provider
    if "minimax" not in providers:
        providers["minimax"] = MINIMAX_PROVIDER.copy()
        changed = True
        print("  + minimax added")

    # Clean stale keys from all providers
    for name, prov in providers.items():
        if isinstance(prov, dict):
            clean_provider_config(prov)

    config["provider"] = providers

    if changed:
        # Backup original
        backup = config_path + ".bak"
        if not os.path.exists(backup):
            shutil.copy2(config_path, backup)

        with open(config_path, 'w') as f:
            json.dump(config, f, indent=2, ensure_ascii=False)
            f.write('\n')
        return True
    return False


def main():
    print("Distributing provider configs from opencode_initializer...\n")

    projects = sorted(glob.glob(f"{PROJECTS_DIR}/*/opencode.json"))
    updated = 0

    for config_path in projects:
        proj = os.path.basename(os.path.dirname(config_path))
        if proj == "opencode_initializer":
            print(f"[{proj}] SKIP (reference)")
            continue

        print(f"[{proj}]")
        if update_project_config(config_path):
            print(f"  UPDATED")
            updated += 1
        else:
            print(f"  OK (no changes)")

    print(f"\nDone: {updated}/{len(projects)-1} projects updated")


if __name__ == "__main__":
    main()
