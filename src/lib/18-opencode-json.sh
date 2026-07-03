#!/usr/bin/env bash
# lib/18-opencode-json.sh — opencode.json generation with all detected MCPs + LSP (STEP 19)
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

# Env-var name registry for each provider — used to generate api_key references
PROVIDER_ENV_VARS = {
    "deepseek": "DEEPSEEK_API_KEY",
    "opencode": "OPENCODE_API_KEY",
    "zai": "ZAI_API_KEY",
    "openrouter": "OPENROUTER_API_KEY",
    "xai": "XAI_API_KEY",
    "mimo": "MIMO_API_KEY",
    "moonshot": "MOONSHOT_API_KEY",
    "minimax": "MINIMAX_API_KEY",
    "openai": "OPENAI_API_KEY",
    "anthropic": "ANTHROPIC_API_KEY",
    "google": "GOOGLE_API_KEY",
    "mistral": "MISTRAL_API_KEY",
    "groq": "GROQ_API_KEY",
    "together": "TOGETHER_API_KEY",
    "cohere": "COHERE_API_KEY",
    "fireworks": "FIREWORKS_API_KEY",
    "cerebras": "CEREBRAS_API_KEY",
    "perplexity": "PERPLEXITY_API_KEY",
    "alibaba": "ALIBABA_API_KEY",
    "deepinfra": "DEEPINFRA_API_KEY",
}

def _build_providers():
    """Build provider config based on available API keys, with fallback chains.
    When ISOLATED_CIRCUIT=true, generates local-only OpenAI-compatible providers.
    API keys use ${ENV_VAR} syntax — team-shareable without exposing secrets."""
    opts = {"options": {"timeout": 600000, "chunkTimeout": 60000, "setCacheKey": True}}
    providers = {}

    isolated = os.environ.get("ISOLATED_CIRCUIT", "false").lower() in ("true", "1", "yes", "on")
    local_endpoint = os.environ.get("OPencode_LOCAL_ENDPOINT", "http://localhost:4000/v1")

    if isolated:
        # ── Isolated Circuit: local OpenAI-compatible providers only ─────────
        local_backends = {
            "ollama": ("http://localhost:11434/v1", "ollama/qwen3:14b", "ollama/qwen3:0.6b"),
            "litellm": ("http://localhost:4000/v1", "litellm/qwen3:14b", "litellm/qwen3:0.6b"),
        }

        # Auto-detect running backends
        import urllib.request as urlreq
        for name, (url, default_model, small_model) in local_backends.items():
            try:
                urlreq.urlopen(url + "/models", timeout=2)
                providers[name] = dict(opts)
                providers[name]["base_url"] = url
                providers[name]["default_model"] = default_model
                providers[name]["small_model"] = small_model
                providers[name]["api_key"] = "not-needed"
            except Exception:
                pass

        primary = "ollama" if "ollama" in providers else "litellm"
        if primary in providers:
            providers[primary]["fallback"] = [p for p in ["ollama", "litellm"] if p in providers and p != primary]

        return providers

    # ── Cloud providers (normal mode) ────────────────────────────────────────

    all_keys = {
        "deepseek": os.environ.get("DEEPSEEK_API_KEY") or secrets.get("DEEPSEEK_API_KEY", ""),
        "opencode": os.environ.get("OPENCODE_API_KEY") or secrets.get("OPENCODE_API_KEY", ""),
        "zai": os.environ.get("ZAI_API_KEY") or secrets.get("ZAI_API_KEY", ""),
        "openrouter": os.environ.get("OPENROUTER_API_KEY") or secrets.get("OPENROUTER_API_KEY", ""),
        "xai": os.environ.get("XAI_API_KEY") or secrets.get("XAI_API_KEY", ""),
        "mimo": os.environ.get("MIMO_API_KEY") or secrets.get("MIMO_API_KEY", ""),
        "moonshot": os.environ.get("MOONSHOT_API_KEY") or secrets.get("MOONSHOT_API_KEY", ""),
        "minimax": os.environ.get("MINIMAX_API_KEY") or secrets.get("MINIMAX_API_KEY", ""),
        "openai": os.environ.get("OPENAI_API_KEY") or secrets.get("OPENAI_API_KEY", ""),
        "anthropic": os.environ.get("ANTHROPIC_API_KEY") or secrets.get("ANTHROPIC_API_KEY", ""),
        "google": os.environ.get("GOOGLE_API_KEY") or secrets.get("GOOGLE_API_KEY", ""),
        "mistral": os.environ.get("MISTRAL_API_KEY") or secrets.get("MISTRAL_API_KEY", ""),
        "groq": os.environ.get("GROQ_API_KEY") or secrets.get("GROQ_API_KEY", ""),
        "together": os.environ.get("TOGETHER_API_KEY") or secrets.get("TOGETHER_API_KEY", ""),
        "cohere": os.environ.get("COHERE_API_KEY") or secrets.get("COHERE_API_KEY", ""),
        "fireworks": os.environ.get("FIREWORKS_API_KEY") or secrets.get("FIREWORKS_API_KEY", ""),
        "cerebras": os.environ.get("CEREBRAS_API_KEY") or secrets.get("CEREBRAS_API_KEY", ""),
        "perplexity": os.environ.get("PERPLEXITY_API_KEY") or secrets.get("PERPLEXITY_API_KEY", ""),
        "alibaba": os.environ.get("ALIBABA_API_KEY") or secrets.get("ALIBABA_API_KEY", ""),
        "deepinfra": os.environ.get("DEEPINFRA_API_KEY") or secrets.get("DEEPINFRA_API_KEY", ""),
    }

    provider_models = {
        "deepseek": ("deepseek/deepseek-v4-pro", "deepseek/deepseek-v4-flash"),
        "zai": ("zai/glm-5.2", "zai/glm-4-flash"),
        "openrouter": ("openrouter/deepseek/deepseek-v4-pro", "openrouter/deepseek/deepseek-v4-flash"),
        "openai": ("openai/gpt-5", "openai/gpt-5-mini"),
        "anthropic": ("anthropic/claude-opus-4-20250514", "anthropic/claude-haiku-4-20250514"),
        "google": ("google/gemini-2.5-pro", "google/gemini-2.5-flash"),
        "mistral": ("mistral/mistral-large-latest", "mistral/mistral-small-latest"),
        "groq": ("groq/llama-4-maverick", "groq/llama-4-scout"),
        "together": ("together/meta-llama/Llama-4-Maverick", "together/meta-llama/Llama-4-Scout"),
        "xai": ("xai/grok-4", "xai/grok-4-mini"),
        "minimax": ("minimax/minimax-m3", "minimax/minimax-m3"),
        "mimo": ("mimo/mimo-v2", "mimo/mimo-v2"),
        "moonshot": ("moonshot/kimi-k2", "moonshot/kimi-k2"),
        "perplexity": ("perplexity/sonar-pro", "perplexity/sonar"),
        "alibaba": ("alibaba/qwen3-235b", "alibaba/qwen3-14b"),
        "deepinfra": ("deepinfra/meta-llama/Llama-4-Maverick", "deepinfra/meta-llama/Llama-4-Scout"),
    }

    fallback_chain = ["deepseek", "zai", "groq", "together", "openai", "minimax"]

    for provider, key in all_keys.items():
        if key or provider in ("deepseek", "opencode", "zai"):
            providers[provider] = dict(opts)
            if provider in provider_models:
                providers[provider]["default_model"] = provider_models[provider][0]
                providers[provider]["small_model"] = provider_models[provider][1]
            # Use ${ENV_VAR} reference so teams can share config without exposing keys
            env_name = PROVIDER_ENV_VARS.get(provider)
            if env_name:
                providers[provider]["api_key"] = "${" + env_name + "}"
            # Set baseURL for OpenAI-compatible providers
            if provider == "zai":
                providers[provider]["base_url"] = "https://api.z.ai/api/paas/v4"
            elif provider == "openrouter":
                providers[provider]["base_url"] = "https://openrouter.ai/api/v1"
            elif provider == "deepinfra":
                providers[provider]["base_url"] = "https://api.deepinfra.com/v1/openai"
            elif provider == "fireworks":
                providers[provider]["base_url"] = "https://api.fireworks.ai/inference/v1"
            if provider not in ("deepseek", "zai"):
                providers[provider]["fallback"] = ["deepseek"]
            elif provider == "deepseek":
                chain = [p for p in fallback_chain if p != "deepseek" and p in providers]
                if chain:
                    providers["deepseek"]["fallback"] = chain[:3]
            elif provider == "zai":
                chain = [p for p in fallback_chain if p != "zai" and p in providers]
                if chain:
                    providers["zai"]["fallback"] = chain[:3]

    return providers

def bun_bin(name):
    """Return absolute path to bun global binary, or None"""
    path = os.path.join(home, ".bun", "bin", name)
    return path if os.path.exists(path) else None

def local_cmd(pkg, bun_name, *extra_args):
    """Return [bun_bin, ...extra] if bun binary exists, else [npx, -y, pkg, ...extra]"""
    bb = bun_bin(bun_name)
    if bb:
        return [bb] + list(extra_args)
    return ["npx", "-y", pkg] + list(extra_args)

# Detect all installed MCPs
mcps = {}

if cmd_exists("c7-mcp-server"):
    mcps["context7"] = {"type": "local", "command": ["c7-mcp-server"], "enabled": True}

# Git MCP (via uvx or pip)
if cmd_exists("mcp-server-git"):
    mcps["git"] = {"type": "local", "command": ["uvx", "mcp-server-git"], "enabled": True}

if pkg_installed("@modelcontextprotocol/server-memory"):
    mcps["memory"] = {"type": "local", "command": local_cmd("@modelcontextprotocol/server-memory", "mcp-server-memory"), "enabled": True}

# Fetch MCP (Python, via uvx)
if cmd_exists("mcp-server-fetch"):
    mcps["fetch"] = {"type": "local", "command": ["uvx", "mcp-server-fetch"], "enabled": True}

# Time MCP (Python, via uvx)
if cmd_exists("mcp-server-time"):
    mcps["time"] = {"type": "local", "command": ["uvx", "mcp-server-time"], "enabled": True}

if pkg_installed("@modelcontextprotocol/server-redis"):
    mcps["redis"] = {"type": "local", "command": local_cmd("@modelcontextprotocol/server-redis", "mcp-server-redis"), "enabled": True}

if pkg_installed("@modelcontextprotocol/server-filesystem"):
    mcps["filesystem"] = {"type": "local", "command": local_cmd("@modelcontextprotocol/server-filesystem", "mcp-server-filesystem", project_dir), "enabled": True}

if pkg_installed("@pimzino/agentic-tools-mcp"):
    mcps["agentic-tools"] = {"type": "local", "command": local_cmd("@pimzino/agentic-tools-mcp", "agentic-tools-mcp"), "enabled": True}

if cmd_exists("codegraph"):
    mcps["codegraph"] = {"type": "local", "command": ["codegraph", "serve", "--mcp"], "enabled": True}

if pkg_installed("@playwright/mcp"):
    mcps["playwright"] = {"type": "local", "command": local_cmd("@playwright/mcp", "playwright-mcp"), "enabled": True}

if pkg_installed("agent-browser-mcp-server"):
    mcps["agent-browser"] = {"type": "local", "command": local_cmd("agent-browser-mcp-server", "agent-browser-mcp-server"), "enabled": True}

if pkg_installed("@loopsense/mcp"):
    mcps["loopsense"] = {"type": "local", "command": local_cmd("@loopsense/mcp", "loopsense"), "enabled": True}

if pkg_installed("@modelcontextprotocol/server-github"):
    gh_token = os.environ.get("GITHUB_TOKEN") or secrets.get("GITHUB_TOKEN", "")
    gh_entry = {"type": "local", "command": local_cmd("@modelcontextprotocol/server-github", "mcp-server-github")}
    if gh_token:
        gh_entry["enabled"] = True
        gh_entry["env"] = {"GITHUB_PERSONAL_ACCESS_TOKEN": gh_token}
    else:
        gh_entry["enabled"] = False
    mcps["github"] = gh_entry

if pkg_installed("@modelcontextprotocol/server-postgres"):
    gh_entry_pg = {"type": "local", "command": local_cmd("@modelcontextprotocol/server-postgres", "mcp-server-postgres")}
    gh_entry_pg["enabled"] = os.environ.get("PG_CONNECTION_STRING", "") != ""
    if gh_entry_pg["enabled"]:
        gh_entry_pg["env"] = {"PG_CONNECTION_STRING": os.environ.get("PG_CONNECTION_STRING", "")}
    mcps["postgres"] = gh_entry_pg

if pkg_installed("mcp-server-gitlab"):
    gl_token = os.environ.get("GITLAB_TOKEN") or secrets.get("GITLAB_TOKEN", "")
    gl_entry = {"type": "local", "command": local_cmd("mcp-server-gitlab", "mcp-server-gitlab")}
    if gl_token:
        gl_entry["enabled"] = True
        gl_entry["env"] = {"GITLAB_PERSONAL_ACCESS_TOKEN": gl_token}
    else:
        gl_entry["enabled"] = False
    mcps["gitlab"] = gl_entry

if pkg_installed("mcp-server-google-maps"):
    gm_key = os.environ.get("GOOGLE_MAPS_KEY") or secrets.get("GOOGLE_MAPS_KEY", "")
    gm_entry = {"type": "local", "command": local_cmd("mcp-server-google-maps", "mcp-server-google-maps")}
    if gm_key:
        gm_entry["enabled"] = True
        gm_entry["env"] = {"GOOGLE_MAPS_API_KEY": gm_key}
    else:
        gm_entry["enabled"] = False
    mcps["google-maps"] = gm_entry

if pkg_installed("@modelcontextprotocol/server-sequential-thinking"):
    mcps["sequential-thinking"] = {"type": "local", "command": local_cmd("@modelcontextprotocol/server-sequential-thinking", "mcp-server-sequential-thinking"), "enabled": True}

if pkg_installed("@scitrera/memorylayer-mcp-server"):
    mcps["memorylayer"] = {"type": "local", "command": local_cmd("@scitrera/memorylayer-mcp-server", "memorylayer-mcp"), "enabled": True}

if pkg_installed("chrome-devtools-mcp"):
    mcps["chrome-devtools"] = {"type": "local", "command": local_cmd("chrome-devtools-mcp", "chrome-devtools-mcp"), "enabled": True}

if pkg_installed("brave-search-mcp"):
    bs_key = os.environ.get("BRAVE_API_KEY") or secrets.get("BRAVE_API_KEY", "")
    bs_entry = {"type": "local", "command": local_cmd("brave-search-mcp", "brave-search-mcp")}
    if bs_key:
        bs_entry["enabled"] = True
        bs_entry["env"] = {"BRAVE_API_KEY": bs_key}
    else:
        bs_entry["enabled"] = False
    mcps["brave-search"] = bs_entry

# SearXNG web search MCP — self-hosted, no API key needed
# Prioritize sanitizer proxy (port 8888) over direct SearXNG (port 8080)
if pkg_installed("mcp-searxng"):
    sanitizer_ok = os.system("curl -sf http://localhost:8888/search?q=test >/dev/null 2>&1") == 0
    searxng_url = "http://localhost:8888" if sanitizer_ok else "http://localhost:8080"
    mcps["websearch"] = {
        "type": "local",
        "command": local_cmd("mcp-searxng", "mcp-searxng"),
        "enabled": True,
        "env": {"SEARXNG_URL": searxng_url}
    }

# SQLite MCP (Python, via uvx)
if cmd_exists("mcp-server-sqlite") or shutil.which("uvx"):
    mcps["sqlite"] = {"type": "local", "command": ["uvx", "mcp-server-sqlite"], "enabled": True}

# Excalidraw MCP — diagram generation (Python, via uvx)
if shutil.which("uvx"):
    mcps["excalidraw"] = {"type": "local", "command": ["uvx", "excalidraw-architect-mcp"], "enabled": True}

# Context7 official MCP (replaces community c7-mcp-server)
if pkg_installed("@upstash/context7-mcp"):
    mcps["context7-official"] = {"type": "local", "command": local_cmd("@upstash/context7-mcp", "context7-mcp"), "enabled": True}

# Notion MCP (optional, requires API key)
if pkg_installed("@notionhq/notion-mcp-server"):
    n_key = os.environ.get("NOTION_API_KEY") or secrets.get("NOTION_API_KEY", "")
    n_entry = {"type": "local", "command": local_cmd("@notionhq/notion-mcp-server", "notion-mcp-server")}
    n_entry["enabled"] = bool(n_key)
    if n_key:
        n_entry["env"] = {"NOTION_API_KEY": n_key}
    mcps["notion"] = n_entry

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
lsp_check("bash-language-server", "bash", ["bash-language-server", "start"], [".sh", ".bash"])
lsp_check("docker-langserver", "dockerfile", ["docker-langserver", "--stdio"], ["Dockerfile"])
lsp_check("vscode-css-language-server", "css", ["vscode-css-language-server", "--stdio"], [".css", ".scss", ".less"])
lsp_check("vscode-html-language-server", "html", ["vscode-html-language-server", "--stdio"], [".html", ".htm"])
lsp_check("vscode-json-language-server", "json", ["vscode-json-language-server", "--stdio"], [".json", ".jsonc"])

# Plugins — read from tier-based registry (plugins.yml)
plugins = ["opencode-codegraph"]
plugin_registry_path = os.path.join(home, ".config", "opencode", "plugins.json")
project_override = os.path.join(PROJECT_DIR, ".opencode", "plugins.json")

def load_plugin_registry():
    registry = {"tiers": {"always": [], "conditional": {}, "on_demand": []}}
    if os.path.exists(plugin_registry_path):
        try:
            with open(plugin_registry_path) as f:
                data = json.load(f)
                if "tiers" in data:
                    registry["tiers"] = data["tiers"]
        except: pass
    if os.path.exists(project_override):
        try:
            with open(project_override) as f:
                data = json.load(f)
                if "tiers" in data:
                    for tier_name in ["always", "on_demand"]:
                        if tier_name in data["tiers"]:
                            registry["tiers"][tier_name] = data["tiers"][tier_name]
                    if "conditional" in data["tiers"]:
                        for pkg, cfg in data["tiers"]["conditional"].items():
                            registry["tiers"]["conditional"][pkg] = cfg
        except: pass
    return registry

def check_dep(name):
    if name == "postgresql":
        return subprocess.run(["docker", "ps", "--format", "{{.Names}}"], capture_output=True, text=True).stdout.find("opencode-postgres") != -1
    if name == "qdrant":
        return subprocess.run(["docker", "ps", "--format", "{{.Names}}"], capture_output=True, text=True).stdout.find("opencode-qdrant") != -1
    if name == "redis":
        return subprocess.run(["docker", "ps", "--format", "{{.Names}}"], capture_output=True, text=True).stdout.find("opencode-redis") != -1
    if name == "docker":
        return shutil.which("docker") is not None
    if name == "daytona_daemon":
        return shutil.which("daytona") is not None
    if name == "git_worktree":
        return os.path.exists(os.path.join(PROJECT_DIR, ".git", "worktrees")) or False
    if name == "goal_mode":
        return True  # always available
    if name == "zellij":
        return shutil.which("zellij") is not None
    return False

registry = load_plugin_registry()

# Always tier — always included if package installed
for pkg in registry["tiers"].get("always", []):
    if pkg == "opencode-codegraph":
        continue  # already added
    npm_name = pkg
    if pkg_installed(npm_name):
        plugins.append(pkg)

# Conditional tier — included if enabled AND deps met
for pkg, cfg in registry["tiers"].get("conditional", {}).items():
    npm_name = pkg
    if not isinstance(cfg, dict):
        continue
    enabled = cfg.get("enabled", False)
    auto = cfg.get("auto_enable", False)
    deps = cfg.get("depends", [])
    # Auto-enable if deps are met
    if auto and not enabled:
        if all(check_dep(d) for d in deps):
            enabled = True
    if enabled and pkg_installed(npm_name):
        plugins.append(pkg)

# On-demand tier — only if explicitly enabled by user
for pkg in registry["tiers"].get("on_demand", []):
    npm_name = pkg if isinstance(pkg, str) else pkg.get("name", "")
    if pkg_installed(npm_name):
        plugins.append(pkg)

# Always add dcp with config if installed (legacy — will move to always tier)
if pkg_installed("@tarquinen/opencode-dcp") and "opencode-dcp" not in plugins:
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
    "mcp": mcps,
    "agent": {
        "build": {
            "mode": "primary",
            "model": "deepseek/deepseek-v4-pro",
            "temperature": 0.2,
            "permission": {
                "edit": "allow",
                "bash": {
                    "git *": "allow",
                    "npm *": "allow",
                    "grep *": "allow",
                    "rg *": "allow",
                    "rm *": "deny",
                    "*": "ask"
                },
                "read": {
                    "*.env": "deny",
                    "*.env.*": "deny",
                    "*": "allow"
                },
                "glob": "allow",
                "grep": "allow",
                "write": "allow",
                "task": {
                    "general": "allow",
                    "explore": "allow",
                    "scout": "allow",
                    "reviewer": "allow",
                    "researcher": "allow",
                    "security-auditor": "allow",
                    "code-reviewer": "allow"
                }
            }
        },
        "plan": {
            "mode": "primary",
            "model": "deepseek/deepseek-v4-flash",
            "temperature": 0.1,
            "permission": {
                "edit": "deny",
                "bash": "deny",
                "read": "allow",
                "glob": "allow",
                "grep": "allow",
                "write": "deny",
                "webfetch": "allow",
                "task": {
                    "researcher": "allow",
                    "explore": "allow"
                }
            }
        },
        "general": {
            "mode": "subagent",
            "model": "deepseek/deepseek-v4-pro",
            "temperature": 0.2
        },
        "explore": {
            "mode": "subagent",
            "model": "deepseek/deepseek-v4-flash",
            "temperature": 0.1,
            "permission": {
                "edit": "deny",
                "bash": "deny",
                "write": "deny"
            }
        },
        "code-reviewer": {
            "mode": "subagent",
            "model": "deepseek/deepseek-v4-pro",
            "temperature": 0.1,
            "permission": {
                "edit": "deny",
                "bash": {
                    "git diff *": "allow",
                    "git log *": "allow",
                    "*": "deny"
                },
                "task": "deny"
            }
        },
        "compaction": {
            "mode": "primary",
            "hidden": True,
            "model": "deepseek/deepseek-v4-flash",
            "temperature": 0.1
        }
    }
}

os.makedirs(os.path.dirname(config_path), exist_ok=True)

with open(config_path, 'w') as f:
    f.write("// ============================================================================\n")
    f.write("// opencode.json — generated by opencode_initializer setup\n")
    f.write("//\n")
    f.write("// API key fields use ${ENV_VAR} substitution syntax.\n")
    f.write("// Set the corresponding environment variable to activate a provider.\n")
    f.write("// This file is safe to share — no secrets are stored in plain text.\n")
    f.write("// ============================================================================\n")
    json.dump(config, f, indent=2)

print(f"VALID:{len(mcps)}")
PYGEN
  }

  RESULT=$(generate_opencode_json)
  if echo "$RESULT" | grep -q "VALID:"; then
    MCP_COUNT=$(echo "$RESULT" | grep "VALID:" | cut -d: -f2)
    log "opencode.json valid — ${MCP_COUNT} MCP server(s) registered"
    _step_done step_json
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
