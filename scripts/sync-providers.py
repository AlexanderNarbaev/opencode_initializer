#!/usr/bin/env python3
"""
Distribute opencode_initializer's provider config to all projects.

Ensures all projects have:
- moonshotai provider with kimi-proxy (tool_call: true)
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
MOONSHOTAI_PROVIDER = {
    "name": "Moonshot Kimi (via local proxy)",
    "npm": "@ai-sdk/openai-compatible",
    "options": {
        "baseURL": "http://127.0.0.1:9876/v1",
        "apiKey": "not-needed-proxy-injects-key"
    },
    "models": {
        "kimi-k3": {
            "name": "Kimi K3",
            "temperature": True,
            "reasoning": True,
            "tool_call": True,
            "modalities": {"input": ["text"], "output": ["text"]},
            "limit": {"context": 1000000, "output": 65536}
        },
        "kimi-k2.7-code": {
            "name": "Kimi K2.7 Code",
            "temperature": True,
            "reasoning": True,
            "tool_call": True,
            "modalities": {"input": ["text"], "output": ["text"]},
            "limit": {"context": 262144, "output": 65536}
        },
        "kimi-k2.7-code-highspeed": {
            "name": "Kimi K2.7 Code Highspeed",
            "temperature": True,
            "reasoning": True,
            "tool_call": True,
            "modalities": {"input": ["text"], "output": ["text"]},
            "limit": {"context": 262144, "output": 65536}
        }
    },
    "default_model": "moonshotai/kimi-k3",
    "small_model": "moonshotai/kimi-k2.7-code",
    "fallback": ["deepseek"]
}

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

LITELLM_PROVIDER = {
    "npm": "@ai-sdk/openai-compatible",
    "name": "LiteLLM Proxy (Kimi)",
    "options": {
        "baseURL": "http://127.0.0.1:9876/v1",
        "apiKey": "sk-1234"
    },
    "models": {
        "kimi-k3": {
            "name": "Kimi K3 (via LiteLLM)",
            "temperature": True,
            "reasoning": True,
            "tool_call": True,
            "modalities": {"input": ["text"], "output": ["text"]},
            "limit": {"context": 1000000, "output": 65536}
        },
        "kimi-k2.7-code": {
            "name": "Kimi K2.7 Code (via LiteLLM)",
            "temperature": True,
            "reasoning": True,
            "tool_call": True,
            "modalities": {"input": ["text"], "output": ["text"]},
            "limit": {"context": 262144, "output": 65536}
        },
        "kimi-k2.7-code-highspeed": {
            "name": "Kimi K2.7 Code Highspeed (via LiteLLM)",
            "temperature": True,
            "reasoning": True,
            "tool_call": True,
            "modalities": {"input": ["text"], "output": ["text"]},
            "limit": {"context": 262144, "output": 65536}
        }
    }
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

    # Update moonshotai provider
    if providers.get("moonshotai") != MOONSHOTAI_PROVIDER:
        providers["moonshotai"] = MOONSHOTAI_PROVIDER.copy()
        changed = True
        print("  + moonshotai updated (tool_call: true, proxy config)")

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

    # Update litellm provider (only for opencode_initializer)
    if "litellm" not in providers and "opencode_initializer" in config_path:
        providers["litellm"] = LITELLM_PROVIDER.copy()
        changed = True
        print("  + litellm added")

    # Clean stale keys from all providers
    for name, prov in providers.items():
        if isinstance(prov, dict):
            clean_provider_config(prov)

    # Ensure tool_call: true for all Kimi models in all providers
    for prov_name, prov_data in providers.items():
        if not isinstance(prov_data, dict):
            continue
        models = prov_data.get("models", {})
        for model_name, model_data in models.items():
            if "kimi" in model_name and isinstance(model_data, dict):
                if model_data.get("tool_call") is not True:
                    model_data["tool_call"] = True
                    changed = True
                    print(f"  + {prov_name}/{model_name} tool_call=true")

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
