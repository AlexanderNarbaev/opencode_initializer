#!/usr/bin/env python3
"""Idempotently register newly-installed plugins in the live opencode.json.

One-off helper for the M7 central-plugin-registration task. Appends plugin
names that are already installed (npm list -g) and not yet present in the
`plugin` array, preserving the existing entries (including the
["opencode-dcp", {...}] object) verbatim.
"""
import json
import pathlib
import subprocess

CFG = pathlib.Path.home() / ".config" / "opencode" / "opencode.json"

ADD = [
    "opencode-token-tracker",
    "opencode-orchestrator",
    "opencode-daytona",
    "opencode-cache-injector",
    "opencode-cache-switch",
    "opencode-cache-ttl",
    "@vikrant82/opencode-cache-keepalive",
    "opencode-cache-hit",
    "@skybluejacket/opencode-context-compress",
    "opencode-context-guard",
    "opencode-context-watch",
    "opencode-models-discovery",
    "opencode-provider-manager",
]


def installed(name: str) -> bool:
    r = subprocess.run(
        ["npm", "list", "-g", "--depth=0"],
        capture_output=True,
        text=True,
    )
    return name in r.stdout


def main() -> None:
    data = json.loads(CFG.read_text())
    plugins = data.get("plugin", [])
    before = len(plugins)
    added = []
    for name in ADD:
        if name not in plugins and installed(name):
            plugins.append(name)
            added.append(name)
    data["plugin"] = plugins
    CFG.write_text(json.dumps(data, indent=2) + "\n")
    print(f"before={before} after={len(plugins)} added={len(added)}")
    for a in added:
        print(f"  + {a}")


if __name__ == "__main__":
    main()
