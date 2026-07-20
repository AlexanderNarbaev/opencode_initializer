#!/usr/bin/env python3
"""Apply kimi-proxy baseURL to all projects' opencode.json"""
import json
import os
import sys

PROVIDER_BLOCK = {
    "deepseek": {
        "options": {"timeout": 600000, "chunkTimeout": 60000, "setCacheKey": True},
        "fallback": ["opencode", "moonshotai", "minimax", "mimo"]
    },
    "opencode": {
        "fallback": ["deepseek", "moonshotai", "minimax", "mimo"]
    },
    "moonshotai": {
        "npm": "@ai-sdk/openai-compatible",
        "name": "Moonshot Kimi (via local Anthropic proxy)",
        "options": {
            "baseURL": "http://127.0.0.1:9876/v1",
            "apiKey": "not-needed-proxy-injects-key"
        },
        "models": {
            "kimi-k3": {
                "name": "Kimi K3",
                "temperature": True,
                "reasoning": True,
                "tool_call": False,
                "modalities": {"input": ["text"], "output": ["text"]},
                "limit": {"context": 1000000, "output": 65536}
            },
            "kimi-k2.7-code": {
                "name": "Kimi K2.7 Code",
                "temperature": True,
                "reasoning": True,
                "tool_call": False,
                "modalities": {"input": ["text"], "output": ["text"]},
                "limit": {"context": 262144, "output": 65536}
            },
            "kimi-k2.7-code-highspeed": {
                "name": "Kimi K2.7 Code Highspeed",
                "temperature": True,
                "reasoning": True,
                "tool_call": False,
                "modalities": {"input": ["text"], "output": ["text"]},
                "limit": {"context": 262144, "output": 65536}
            }
        },
        "fallback": ["deepseek", "opencode"]
    },
    "minimax": {
        "npm": "@ai-sdk/openai-compatible",
        "name": "MiniMax",
        "options": {"timeout": 600000, "chunkTimeout": 60000, "setCacheKey": True,
                    "baseURL": "https://api.minimax.io/v1"},
        "fallback": ["deepseek", "opencode"]
    },
    "mimo": {
        "npm": "@ai-sdk/openai-compatible",
        "name": "MiMo",
        "options": {"timeout": 600000, "chunkTimeout": 60000, "setCacheKey": True},
        "fallback": ["deepseek", "opencode"]
    }
}

projects = ['agi', 'ThePath', 'opora', 'opora-landing', 'rag-system',
            'rag-system-bak', 'DeepSeek', 'opencode_initializer']
base = '/home/alexandr-narbaev/Projects'

errors = []
for name in projects:
    path = f'{base}/{name}/opencode.json'
    try:
        with open(path) as f:
            cfg = json.load(f)
        cfg['provider'] = PROVIDER_BLOCK
        cfg.setdefault('agent', {}).setdefault('build', {
            'mode': 'primary',
            'model': cfg.get('model', 'deepseek/deepseek-v4-pro'),
            'temperature': 0.2
        })
        # Re-link MCP filesystem path if applicable
        fs_cmd = cfg.get('mcp', {}).get('filesystem', {}).get('command')
        if fs_cmd and isinstance(fs_cmd, list) and len(fs_cmd) >= 2:
            cfg['mcp']['filesystem']['command'] = [
                fs_cmd[0],
                f'{base}/{name}'
            ]
        with open(path, 'w') as f:
            json.dump(cfg, f, indent=2, ensure_ascii=False)
            f.write('\n')
        provs = list(cfg['provider'].keys())
        print(f'OK  {name}: providers={provs}')
    except Exception as e:
        errors.append(f'{name}: {e}')
        print(f'ERR {name}: {e}')

if errors:
    print(f'\n{len(errors)} errors:')
    for e in errors:
        print(f'  - {e}')
    sys.exit(1)
print(f'\nAll {len(projects)} projects updated.')