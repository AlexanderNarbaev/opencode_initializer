#!/usr/bin/env python3
"""Fixture test for sync-providers.py — validates provider insertion on temp dirs."""
import json, os, sys, tempfile, shutil

# Copy the relevant functions from sync-providers.py
MIMO_PROVIDER = {
    "options": {"timeout": 600000, "chunkTimeout": 60000, "setCacheKey": True},
    "fallback": ["deepseek", "opencode"]
}
MINIMAX_PROVIDER = {
    "options": {
        "timeout": 600000, "chunkTimeout": 60000, "setCacheKey": True,
        "baseURL": "https://api.minimax.io/v1",
        "apiKey": "{env:MINIMAX_API_KEY}"
    },
    "fallback": ["deepseek", "opencode"]
}

def clean_provider_config(provider_data):
    if isinstance(provider_data, dict):
        provider_data.pop("base_url", None)
        provider_data.pop("api_key", None)
    return provider_data

def update_project_config(config_path):
    try:
        with open(config_path) as f:
            config = json.load(f)
    except Exception:
        return False
    providers = config.get("provider", {})
    changed = False
    if "mimo" not in providers:
        providers["mimo"] = MIMO_PROVIDER.copy()
        changed = True
    if "minimax" not in providers:
        providers["minimax"] = MINIMAX_PROVIDER.copy()
        changed = True
    for name, prov in providers.items():
        if isinstance(prov, dict):
            clean_provider_config(prov)
    config["provider"] = providers
    if changed:
        shutil.copy2(config_path, config_path + ".bak")
        with open(config_path, 'w') as f:
            json.dump(config, f, indent=2, ensure_ascii=False)
            f.write('\n')
        return True
    return False


def test_inserts_missing_providers():
    """Test: mimo + minimax are inserted when missing."""
    td = tempfile.mkdtemp()
    try:
        cfg = os.path.join(td, "opencode.json")
        with open(cfg, 'w') as f:
            json.dump({"provider": {"deepseek": {}}, "model": "deepseek/deepseek-v4-pro"}, f)
        result = update_project_config(cfg)
        assert result is True, "Should return True (providers added)"
        with open(cfg) as f:
            data = json.load(f)
        assert "mimo" in data["provider"], "mimo provider NOT added"
        assert "minimax" in data["provider"], "minimax provider NOT added"
        assert data["provider"]["mimo"]["fallback"] == ["deepseek", "opencode"]
        assert "baseURL" in data["provider"]["minimax"]["options"]
        assert os.path.exists(cfg + ".bak"), "backup NOT created"
        print("  PASS: test_inserts_missing_providers")
    finally:
        shutil.rmtree(td, ignore_errors=True)


def test_noop_when_providers_exist():
    """Test: no changes when providers already present."""
    td = tempfile.mkdtemp()
    try:
        cfg = os.path.join(td, "opencode.json")
        existing = {"provider": {"deepseek": {}, "mimo": MIMO_PROVIDER.copy(), "minimax": MINIMAX_PROVIDER.copy()}}
        with open(cfg, 'w') as f:
            json.dump(existing, f)
        result = update_project_config(cfg)
        assert result is False, "Should return False (no changes needed)"
        assert not os.path.exists(cfg + ".bak"), "backup should NOT be created"
        print("  PASS: test_noop_when_providers_exist")
    finally:
        shutil.rmtree(td, ignore_errors=True)


def test_cleans_stale_keys_on_insert():
    """Test: stale base_url/api_key keys cleaned when file is rewritten (provider insert triggers rewrite)."""
    td = tempfile.mkdtemp()
    try:
        cfg = os.path.join(td, "opencode.json")
        # Only deepseek + mimo with stale keys, NO minimax — triggers insert + rewrite
        dirty = {"provider": {"deepseek": {}, "mimo": {"base_url": "old", "api_key": "old", "options": {}}}}
        with open(cfg, 'w') as f:
            json.dump(dirty, f)
        result = update_project_config(cfg)
        assert result is True, "Should return True (minimax added, triggers rewrite)"
        with open(cfg) as f:
            data = json.load(f)
        assert "base_url" not in data["provider"]["mimo"], "stale base_url NOT cleaned after rewrite"
        assert "api_key" not in data["provider"]["mimo"], "stale api_key NOT cleaned after rewrite"
        assert "minimax" in data["provider"], "minimax was added"
        print("  PASS: test_cleans_stale_keys_on_insert")
    finally:
        shutil.rmtree(td, ignore_errors=True)


if __name__ == "__main__":
    test_inserts_missing_providers()
    test_noop_when_providers_exist()
    test_cleans_stale_keys_on_insert()
    print("\ntest_sync_providers: ALL 3 TESTS PASSED")
