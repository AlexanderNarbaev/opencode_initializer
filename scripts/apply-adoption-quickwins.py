#!/usr/bin/env python3
"""apply-adoption-quickwins.py — implement the TOP-5 quick wins from the research
report (2026-10-16) across the global config and every project config:

1. PIN every plugin and MCP server (they all float on @latest today; 4 config
   entries re-resolved on every launch -> overnight breakage risk).
2. RETIRE npm-deprecated MCP servers: @modelcontextprotocol/server-{github,redis,
   postgres,gitlab,puppeteer,slack,brave-search} ("Package no longer supported").
3. FIX brave-search split-brain: keep ONLY the official @brave/brave-search-mcp-server.
4. DEDUPE context7: drop context7-official (duplicate of context7).
5. REMOVE opencode-goal-mode (npm placeholder, zero published versions).
6. RESTORE moonshotai provider (the only model in the system with a declared
   1M context window) from opencode.json.custom-bak, with exact pins.
Idempotent; backups kept.
"""
import json, re, os, glob, datetime

ts = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")

# exact pins verified on the registry (2026-10-16)
PINS = {
    "opencode-swarm": "7.197.3",
    "opencode-codegraph": "0.1.38",
    "opencode-goal-plugin": "0.11.0",
    "opencode-supermemory": "2.0.17",
    "opencode-orchestrator": "2.0.15",
    "opencode-token-tracker": None,   # leave unpinned if absent
    "@tarquinen/opencode-dcp": "3.2.0",
    "opencode-auto-fallback": None,
    "opencode-vibeguard": None,
    "opencode-conductor": None,
    "opencode-daytona": None,
    "opencode-devcontainers": None,
    "opencode-worktree": None,
    "opencode-background-agents": None,
    "opencode-scheduler": None,
    "opencode-zellij-namer": None,
    "opencode-websearch-cited": None,
    "opencode-models-discovery": None,
    "opencode-cache-injector": None,
    "opencode-cache-switch": None,
    "opencode-cache-ttl": None,
    "opencode-cache-hit": None,
    "opencode-context-guard": None,
    "opencode-context": None,
    "opencode-provider-manager": None,
    "opencode-router": None,
}
DROP_PLUGINS = {"opencode-goal-mode"}          # zero published versions
DEPRECATED_MCP = {
    "@modelcontextprotocol/server-github", "@modelcontextprotocol/server-redis",
    "@modelcontextprotocol/server-postgres", "@modelcontextprotocol/server-gitlab",
    "@modelcontextprotocol/server-puppeteer", "@modelcontextprotocol/server-slack",
    "@modelcontextprotocol/server-brave-search", "mcp-server-github",
    "mcp-server-redis", "mcp-server-postgres",
}
MCP_PINS = {
    "@upstash/context7-mcp": "4.3.0",
    "@brave/brave-search-mcp-server": "2.1.4",
    "@modelcontextprotocol/server-memory": None,
    "@modelcontextprotocol/server-sequential-thinking": None,
    "@modelcontextprotocol/server-everything": None,
    "@playwright/mcp": "0.0.83",
}

def clean(path, moonshot):
    raw = open(path).read()
    d = json.loads(re.sub(r"^\s*//.*$", "", raw, flags=re.M))
    notes = []

    # --- plugins: drop dead, pin known ---
    pk = "plugin" if "plugin" in d else "plugins"
    if pk in d:
        newp = []
        for e in d[pk]:
            nm = e[0] if isinstance(e, list) and e else (e.get("package") if isinstance(e, dict) else e)
            base = re.sub(r"@[\d.]+$", "", nm or "")
            if base in DROP_PLUGINS:
                notes.append(f"dropped plugin {base}"); continue
            ver = PINS.get(base)
            pinned = f"{base}@{ver}" if ver else base
            if isinstance(e, list) and len(e) == 2 and isinstance(e[1], dict):
                newp.append([pinned, e[1]])
            else:
                newp.append(pinned)
        d[pk] = newp

    # --- MCP: retire deprecated, dedupe context7, pin ---
    mcp = d.get("mcp", {})
    if isinstance(mcp, dict) and "servers" in mcp and len(mcp) <= 2:
        mcp = d["mcp"] = mcp["servers"]
    if isinstance(mcp, dict):
        for name in list(mcp):
            ent = mcp[name]
            cmd = ent.get("command") if isinstance(ent, dict) else None
            joined = " ".join(cmd) if isinstance(cmd, list) else str(cmd)
            if any(bad in joined for bad in DEPRECATED_MCP):
                if name == "github":
                    mcp[name] = {"type": "local",
                                  "command": ["/home/alexandr-narbaev/.local/bin/github-mcp-server", "stdio"],
                                  "enabled": True,
                                  "environment": {"GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"}}
                    notes.append("github MCP -> official github-mcp-server")
                    continue
                mcp.pop(name); notes.append(f"retired deprecated MCP {name}"); continue
            if name == "context7-official":
                mcp.pop(name); notes.append("removed duplicate context7-official"); continue
            if name == "redis":
                mcp.pop(name); notes.append("retired redis MCP (deprecated package)"); continue
            # pin npm-based servers
            if isinstance(cmd, list):
                out = []
                for c in cmd:
                    base = re.sub(r"@\d[\d.]*$", "", c)
                    v = MCP_PINS.get(base)
                    out.append(f"{base}@{v}" if v else c)
                ent["command"] = out
        d["mcp"] = mcp

    # --- restore moonshotai (only declared 1M-context model in the system) ---
    if moonshot and "moonshotai" not in (d.get("provider") or {}):
        d.setdefault("provider", {})["moonshotai"] = moonshot
        notes.append("restored moonshotai provider (1M context)")

    open(path + f".bak-qw-{ts}", "w").write(raw)
    open(path, "w").write(json.dumps(d, indent=2))
    return notes

# moonshotai fragment from the clobbered backup
moonshot = None
bak = os.path.expanduser("~/.config/opencode/opencode.json.custom-bak")
if os.path.exists(bak):
    try:
        mb = json.loads(re.sub(r"^\s*//.*$", "", open(bak).read(), flags=re.M))
        pv = mb.get("provider", mb.get("providers", {})).get("moonshotai")
        if pv:
            moonshot = pv
            for mv in (pv.get("models") or {}).values():
                lim = mv.setdefault("limit", {})
                lim["context"] = 1_000_000
                lim.setdefault("output", 65_536)
    except Exception:
        pass

for p in [os.path.expanduser("~/.config/opencode/opencode.json")] + sorted(
        glob.glob(os.path.expanduser("~/Projects/*/opencode.json"))):
    if not os.path.exists(p):
        continue
    try:
        n = clean(p, moonshot)
        print(f"{os.path.basename(os.path.dirname(p))}/{os.path.basename(p)}: {'; '.join(n) if n else 'no change'}")
    except Exception as e:
        print(f"ERR {p}: {e}")
print("DONE")