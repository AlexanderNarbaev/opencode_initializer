#!/usr/bin/env bash
# lib/18-opencode-json.sh — opencode.json generation with all detected MCPs + LSP (STEP 14)
# Requires: MODE, PROJECT_DIR
set -euo pipefail

if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "fix-config" ]; then
  section "Generating opencode.json with all MCPs"

  generate_opencode_json() {
    python3 << 'PYGEN'
import json, os, shutil

home = os.path.expanduser("~")
project_dir = os.environ.get("PROJECT_DIR", os.path.join(home, "projects"))
config_path = os.path.join(home, ".config", "opencode", "opencode.json")

# Load existing config to preserve user choices
existing_mcp = {}
if os.path.exists(config_path):
    try:
        with open(config_path) as f:
            existing = json.load(f)
            existing_mcp = existing.get("mcp", {})
    except:
        pass

# Load secrets from secrets.env for provider and token detection
secrets = {}
secrets_file = os.path.join(home, ".config", "opencode", "secrets.env")
if os.path.exists(secrets_file):
    try:
        for line in open(secrets_file).readlines():
            line = line.strip()
            if "=" in line:
                line = line.replace("export ", "", 1)
                k, v = line.split("=", 1)
                secrets[k.strip()] = v.strip().strip('"').strip("'")
    except:
        pass

def cmd_exists(cmd):
    return shutil.which(cmd) is not None

def npx_available():
    return shutil.which("npx") is not None or shutil.which("bunx") is not None

def pkg_installed(pkg_name):
    """Check if npm package is installed globally (npm or bun)"""
    if cmd_exists(pkg_name):
        return True
    try:
        result = os.popen(f"npm list -g {pkg_name} 2>/dev/null").read()
        if pkg_name in result and "(empty)" not in result:
            return True
    except:
        pass
    try:
        result = os.popen(f"bun pm ls -g 2>/dev/null").read()
        if pkg_name in result:
            return True
    except:
        pass
    return False

def _build_providers():
    """Build provider config based on available API keys."""
    opts = {"options": {"timeout": 600000, "chunkTimeout": 60000, "setCacheKey": True}}
    providers = {}
    providers["deepseek"] = dict(opts)
    providers["opencode"] = dict(opts)
    xai_key = os.environ.get("XAI_API_KEY") or secrets.get("XAI_API_KEY", "")
    mimo_key = os.environ.get("MIMO_API_KEY") or secrets.get("MIMO_API_KEY", "")
    moonshot_key = os.environ.get("MOONSHOT_API_KEY") or secrets.get("MOONSHOT_API_KEY", "")
    minimax_key = os.environ.get("MINIMAX_API_KEY") or secrets.get("MINIMAX_API_KEY", "")
    if xai_key:
        providers["xai"] = dict(opts)
    if mimo_key:
        providers["mimo"] = dict(opts)
    if moonshot_key:
        providers["moonshot"] = dict(opts)
    if minimax_key:
        providers["minimax"] = dict(opts)
    return providers

# Detect all installed MCPs
mcps = {}

if cmd_exists("c7-mcp-server"):
    mcps["context7"] = {"type": "local", "command": ["c7-mcp-server"], "enabled": True}

if pkg_installed("@modelcontextprotocol/server-filesystem"):
    mcps["filesystem"] = {"type": "local", "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", project_dir], "enabled": True}

if pkg_installed("@pimzino/agentic-tools-mcp"):
    mcps["agentic-tools"] = {"type": "local", "command": ["npx", "-y", "@pimzino/agentic-tools-mcp"], "enabled": True}

if cmd_exists("codegraph"):
    mcps["codegraph"] = {"type": "local", "command": ["codegraph", "serve", "--mcp"], "enabled": True}

if pkg_installed("@playwright/mcp"):
    mcps["playwright"] = {"type": "local", "command": ["npx", "-y", "@playwright/mcp"], "enabled": True}

if pkg_installed("agent-browser-mcp-server"):
    mcps["agent-browser"] = {"type": "local", "command": ["npx", "-y", "agent-browser-mcp-server"], "enabled": True}

if pkg_installed("@loopsense/mcp"):
    mcps["loopsense"] = {"type": "local", "command": ["npx", "-y", "@loopsense/mcp"], "enabled": True}

if pkg_installed("@modelcontextprotocol/server-github"):
    gh_token = os.environ.get("GITHUB_TOKEN") or secrets.get("GITHUB_TOKEN", "")
    gh_entry = {"type": "local", "command": ["npx", "-y", "@modelcontextprotocol/server-github"]}
    if gh_token:
        gh_entry["enabled"] = True
        gh_entry["env"] = {"GITHUB_PERSONAL_ACCESS_TOKEN": gh_token}
    else:
        gh_entry["enabled"] = False
    mcps["github"] = gh_entry

if pkg_installed("@modelcontextprotocol/server-postgres"):
    gh_entry_pg = {"type": "local", "command": ["npx", "-y", "@modelcontextprotocol/server-postgres"]}
    gh_entry_pg["enabled"] = os.environ.get("PG_CONNECTION_STRING", "") != ""
    if gh_entry_pg["enabled"]:
        gh_entry_pg["env"] = {"PG_CONNECTION_STRING": os.environ.get("PG_CONNECTION_STRING", "")}
    mcps["postgres"] = gh_entry_pg

if pkg_installed("@anthropic/mcp-server-gitlab"):
    gl_token = os.environ.get("GITLAB_TOKEN") or secrets.get("GITLAB_TOKEN", "")
    gl_entry = {"type": "local", "command": ["npx", "-y", "@anthropic/mcp-server-gitlab"]}
    if gl_token:
        gl_entry["enabled"] = True
        gl_entry["env"] = {"GITLAB_PERSONAL_ACCESS_TOKEN": gl_token}
    else:
        gl_entry["enabled"] = False
    mcps["gitlab"] = gl_entry

if pkg_installed("@anthropic/mcp-server-google-maps"):
    gm_key = os.environ.get("GOOGLE_MAPS_KEY") or secrets.get("GOOGLE_MAPS_KEY", "")
    gm_entry = {"type": "local", "command": ["npx", "-y", "@anthropic/mcp-server-google-maps"]}
    if gm_key:
        gm_entry["enabled"] = True
        gm_entry["env"] = {"GOOGLE_MAPS_API_KEY": gm_key}
    else:
        gm_entry["enabled"] = False
    mcps["google-maps"] = gm_entry

if pkg_installed("@modelcontextprotocol/server-sequential-thinking"):
    mcps["sequential-thinking"] = {"type": "local", "command": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"], "enabled": True}

if pkg_installed("@scitrera/memorylayer-mcp-server"):
    mcps["memorylayer"] = {"type": "local", "command": ["npx", "-y", "@scitrera/memorylayer-mcp-server"], "enabled": True}

# Remote MCP servers (no local binary needed)
mcps["sentry"] = {"type": "remote", "url": "https://mcp.sentry.dev/mcp", "enabled": existing_mcp.get("sentry", {}).get("enabled", False), "timeout": 30000}
mcps["grep"] = {"type": "remote", "url": "https://mcp.grep.app", "enabled": existing_mcp.get("grep", {}).get("enabled", False), "timeout": 30000}

# LSP servers — detect installed, configure in opencode.json
lsp_config = {}

def lsp_check(binary_name, lsp_key, lsp_command, extensions):
    if cmd_exists(binary_name):
        lsp_config[lsp_key] = {"command": lsp_command, "extensions": extensions}

lsp_check("gopls", "gopls", ["gopls"], [".go"])
lsp_check("rust-analyzer", "rust-analyzer", ["rust-analyzer"], [".rs"])
lsp_check("typescript-language-server", "typescript", ["typescript-language-server", "--stdio"], [".ts", ".tsx", ".js", ".jsx"])
lsp_check("pyright-langserver", "pyright", ["pyright-langserver", "--stdio"], [".py"])
lsp_check("omnisharp", "omnisharp", ["omnisharp", "--stdio"], [".cs"])
lsp_check("yaml-language-server", "yaml", ["yaml-language-server", "--stdio"], [".yaml", ".yml"])
lsp_check("marksman", "marksman", ["marksman", "server"], [".md"])
lsp_check("taplo", "taplo", ["taplo", "lsp", "stdio"], [".toml"])
lsp_check("lua-language-server", "lua", ["lua-language-server"], [".lua"])
lsp_check("zls", "zls", ["zls"], [".zig"])

# Plugins — opencode-codegraph (always) + conditional
plugins = ["opencode-codegraph"]
if pkg_installed("open-orchestra"):
    plugins.append("open-orchestra")
if pkg_installed("@tarquinen/opencode-dcp"):
    plugins.append(["opencode-dcp", {
        "compress": {
            "enabled": True,
            "minContextLimit": 20000,
            "maxContextLimit": 48000,
            "autoCompaction": True
        },
        "prune": {
            "enabled": True,
            "protectTokens": 40000,
            "minTokens": 20000
        }
    }])
if pkg_installed("opencode-lazy-loader"):
    plugins.append("opencode-lazy-loader")
if pkg_installed("@gitdamnit/opencode-stranger-danger"):
    plugins.append("opencode-stranger-danger")
if pkg_installed("opencode-damage-control"):
    plugins.append(["opencode-damage-control", {
        "guardrails": {
            "input": {
                "piiFiltering": True,
                "promptInjectionPrevention": True
            },
            "deterministicPolicies": {
                "blockedCommands": ["rm -rf /", "DROP TABLE", "terraform destroy"],
                "blockedPaths": ["~/.ssh", "~/.aws", ".env"]
            }
        },
        "audit": {
            "logTamperResistant": True,
            "logRetentionDays": 365
        }
    }])
if pkg_installed("opencode-auto-fallback"):
    plugins.append("opencode-auto-fallback")

# Build config
config = {
    "$schema": "https://opencode.ai/config.json",
    "model": "deepseek/deepseek-v4-pro",
    "small_model": "deepseek/deepseek-v4-flash",
    "default_agent": "build",
    "autoupdate": True,
    "compaction": {
        "auto": True,
        "prune": True,
        "tail_turns": 2,
        "reserved": 10000
    },
    "provider": _build_providers(),
    "tool_output": {
        "max_lines": 2000,
        "max_bytes": 51200
    },
    "watcher": {
        "ignore": ["node_modules/**", "dist/**", ".git/**", "target/**", "__pycache__/**"]
    },
    "experimental": {
        "mcp_timeout": 30000,
        "openTelemetry": True
    },
    "lsp": lsp_config,
    "plugin": plugins,
    "mcp": mcps
}

os.makedirs(os.path.dirname(config_path), exist_ok=True)

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print(f"VALID:{len(mcps)}")
PYGEN
  }

  RESULT=$(generate_opencode_json)
  if echo "$RESULT" | grep -q "VALID:"; then
    MCP_COUNT=$(echo "$RESULT" | grep "VALID:" | cut -d: -f2)
    log "opencode.json valid — ${MCP_COUNT} MCP server(s) registered"
    _step_done step_opencode_json
  else
    warn "opencode.json generation produced unexpected output"
  fi

  # Cold-start verification of each registered MCP
  if [ "${MCP_COUNT:-0}" -gt 0 ] 2>/dev/null; then
    section "MCP cold-start test"
    set +e
    MCP_PASS=0; MCP_FAIL=0
    for mcp_name in $(python3 -c "
import json
c=json.load(open('$HOME/.config/opencode/opencode.json'))
print(' '.join(c.get('mcp',{}).keys()))
" 2>/dev/null); do
      MCP_NAME="$mcp_name" python3 -c "
import json, os, sys
name = os.environ.get('MCP_NAME','')
c = json.load(open(os.path.expanduser('~/.config/opencode/opencode.json')))
m = c.get('mcp',{}).get(name,{})
sys.stdout.write(json.dumps(m.get('command',[])))
" 2>/dev/null > /tmp/opencode-mcp-cmd.$$.json
      mcp_enabled=$(MCP_NAME="$mcp_name" python3 -c "
import json, os
name = os.environ.get('MCP_NAME','')
c = json.load(open(os.path.expanduser('~/.config/opencode/opencode.json')))
m = c.get('mcp',{}).get(name,{})
print(m.get('enabled', True))
" 2>/dev/null)
      mcp_type=$(MCP_NAME="$mcp_name" python3 -c "
import json, os
name = os.environ.get('MCP_NAME','')
c = json.load(open(os.path.expanduser('~/.config/opencode/opencode.json')))
m = c.get('mcp',{}).get(name,{})
print(m.get('type', 'local'))
" 2>/dev/null)
      if [ "$mcp_enabled" = "False" ] || [ "$mcp_type" = "remote" ]; then
        MCP_PASS=$((MCP_PASS+1))
        continue
      fi
      binary=$(python3 -c "import json,sys; arr=json.load(sys.stdin); print(arr[0] if arr else '')" 2>/dev/null < /tmp/opencode-mcp-cmd.$$.json)
      rm -f /tmp/opencode-mcp-cmd.$$.json
      if echo "$binary" | grep -qE "^(npx|bunx)$"; then
        if which npx &>/dev/null || which bunx &>/dev/null; then
          MCP_PASS=$((MCP_PASS+1))
        else
          warn "MCP $mcp_name: npx/bunx not found"
          MCP_FAIL=$((MCP_FAIL+1))
        fi
      elif [ -n "$binary" ] && which "$binary" &>/dev/null; then
        MCP_PASS=$((MCP_PASS+1))
      else
        warn "MCP $mcp_name: $binary not found"
        MCP_FAIL=$((MCP_FAIL+1))
      fi
    done
    log "MCP cold-start: $MCP_PASS ready, $MCP_FAIL missing"
    set -e
  fi
fi
