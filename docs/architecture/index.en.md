# Architecture

OpenCode Initializer follows a modular architecture: a lightweight **orchestrator** (`setup.sh`, 284 lines) that sources 25 **modules** and dispatches 4 **mode scripts**.

## C4 Level 1: System Context

```mermaid
C4Context
    title opencode_initializer — System Context

    Person(dev, "Developer", "Wants a ready-to-use AI-enhanced dev environment")
    System(oci, "OpenCode Initializer", "Bootstraps complete dev machine with 8 languages, 21 MCPs, 15 plugins, infrastructure")
    
    System_Ext(gh, "GitHub", "Source code, releases, CI/CD")
    System_Ext(ghp, "GitHub Packages", "npm packages, Docker images")
    System_Ext(apt, "Package Registries", "apt, dnf, pacman, apk, zypper, brew")
    System_Ext(mcp_registry, "MCP Registry", "MCP server packages")
    System_Ext(ai_api, "AI Providers", "OpenCode, DeepSeek, etc.")
    
    Rel(dev, oci, "Runs setup.sh", "curl|bash")
    Rel(oci, gh, "Downloads", "HTTPS")
    Rel(oci, ghp, "Installs packages", "npm, pip, cargo")
    Rel(oci, apt, "Installs system packages", "apt/dnf/pacman")
    Rel(oci, mcp_registry, "Fetches MCP servers", "npm, npx")
    Rel(oci, ai_api, "Configures providers", "HTTPS/API")
    
    UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="2")
```

## C4 Level 2: Container Diagram

```mermaid
C4Container
    title opencode_initializer — Containers

    Container_Boundary(oci, "OpenCode Initializer") {
        Container(setup, "setup.sh", "Bash", "Orchestrator — dispatches modes, loads modules, tracks progress")
        Container(dev_cli, "dev CLI", "Bash", "Post-install management: install, remove, update, health, config")
        Container(lib, "src/lib/ (25 modules)", "Bash", "Core modules: system, languages, tools, MCP, LSP, LLM")
        Container(modes, "src/modes/ (4 modes)", "Bash", "Runtime modes: health, fix-zshrc, upgrade, interactive")
        Container(tests, "tests/", "Bash + Bats", "Unit, integration, E2E test suite")
        Container(docs_site, "Docs Site", "MkDocs Material", "Documentation site (this page)")
    }
    
    System_Ext(gh_actions, "GitHub Actions", "CI/CD — ShellCheck, shfmt, test suite, docs deploy")
    System_Ext(github_pages, "GitHub Pages", "Hosts documentation site")
    
    Rel(setup, lib, "Sources modules", "source")
    Rel(setup, modes, "Dispatches mode", "bash")
    Rel(dev_cli, lib, "Sources helpers", "source")
    Rel(gh_actions, tests, "Runs", "CI trigger")
    Rel(gh_actions, docs_site, "Builds & deploys", "mkdocs build + gh-pages")
    Rel(docs_site, github_pages, "Deployed to", "GitHub Pages")
```

## C4 Level 3: Module Layout

```mermaid
C4Container
    title src/lib/ — 25 Module Layout

    Container_Boundary(modules, "src/lib/") {
        Container(helpers, "helpers.sh", "Bash", "_curl, _retry, _npm_install — shared infrastructure")
        Container(core, "00-core.sh", "Bash", "OS/PKG/ARCH detection, mirrors, progress tracking")
        
        Container(sys, "01-system.sh", "Bash", "System packages (cross-distro)")
        Container(docker, "02-docker.sh", "Bash", "Docker engine")
        Container(chrome, "03-chrome.sh", "Bash", "Google Chrome + chromedriver")
        Container(zsh, "04-zsh.sh", "Bash", "Zsh + Oh My Zsh + P10k + 14 plugins")
        
        Container(java, "05-java.sh", "Bash", "Java 25 (Adoptium)")
        Container(node, "06-node.sh", "Bash", "Node.js 24 (n)")
        Container(python, "07-python.sh", "Bash", "Python 3.14 + uv")
        Container(go, "08-go.sh", "Bash", "Go 1.26")
        Container(rust, "09-rust.sh", "Bash", "Rust 1.96 (rustup)")
        Container(dotnet, "10-dotnet.sh", "Bash", ".NET 10")
        
        Container(opencode, "11-opencode.sh", "Bash", "OpenCode CLI + Bun")
        Container(mcp, "12-mcp-lsp.sh", "Bash", "21 MCP servers + 15 plugins + 13 LSP")
        Container(chromadb, "13-chromadb.sh", "Bash", "ChromaDB + systemd")
        Container(shokunin, "14-shokunin.sh", "Bash", "Shokunin + Superpowers + Caveman")
        Container(sec, "15-security.sh", "Bash", "Trivy, Qodana")
        Container(llm, "16-llm.sh", "Bash", "Ollama, vLLM, SGLang, Open WebUI")
        
        Container(project, "17-project.sh", "Bash", "Project structure (AGENTS.md, WAL)")
        Container(json, "18-opencode-json.sh", "Bash", "opencode.json generation")
        Container(finalize, "19-finalize.sh", "Bash", "Git config, PATH, verification (36 checks)")
        Container(update, "20-autoupdate.sh", "Bash", "topgrade + systemd timer")
        Container(rag, "21-rag.sh", "Bash", "RAG system (optional)")
        
        Container(vcheck, "version-check.sh", "Bash", "Version comparison (8 tools)")
        Container(precheck, "pre-session-check.sh", "Bash", "Pre-session validation")
    }

    Rel(core, helpers, "Uses")
    Rel(sys, core, "Depends")
    Rel(java, core, "Depends")
    Rel(mcp, helpers, "Uses _curl/_npm_install")
    Rel(finalize, json, "Calls")
    Rel(project, core, "Depends")
```

## C4 Level 4: setup.sh Orchestrator Flow

```mermaid
flowchart TD
    A["setup.sh (284 lines)"] --> B["Detect SCRIPT_DIR"]
    B --> C["Source helpers.sh"]
    C --> D["Source 00-core.sh"]
    D --> E{"Parse CLI args"}
    E -->|"--help"| F["Show help + exit"]
    E -->|"--version"| G["Show version + exit"]
    E -->|"--health"| H["Source modes/health.sh"]
    E -->|"--fix-config"| I["Run config fix"]
    E -->|"--dry-run"| J["Preview mode"]
    E -->|"--interactive"| K["Interactive mode"]
    E -->|"--reinit"| L["Reinit mode"]
    E -->|"default (full)"| M["Full bootstrap"]
    
    M --> N["Source 01-system.sh .. 21-rag.sh sequentially"]
    N --> O["Source 18-opencode-json.sh"]
    O --> P["Source 19-finalize.sh"]
    P --> Q["Verification: 36 checks"]
    Q --> R["Done"]
    
    H --> S["60+ diagnostic checks"]
    K --> T["Component-by-component selection"]
```

## Module Dependency Map

```mermaid
graph LR
    subgraph "Infrastructure Layer"
        helpers["helpers.sh"]
        core["00-core.sh"]
    end
    
    subgraph "System Layer"
        sys["01-system.sh"]
        docker["02-docker.sh"]
        chrome["03-chrome.sh"]
        zsh["04-zsh.sh"]
    end
    
    subgraph "Language Layer"
        java["05-java.sh"]
        node["06-node.sh"]
        python["07-python.sh"]
        go["08-go.sh"]
        rust["09-rust.sh"]
        dotnet["10-dotnet.sh"]
    end
    
    subgraph "Tooling Layer"
        opencode["11-opencode.sh"]
        mcp["12-mcp-lsp.sh"]
        chromadb["13-chromadb.sh"]
        shokunin["14-shokunin.sh"]
        sec["15-security.sh"]
        llm["16-llm.sh"]
        rag["21-rag.sh"]
    end
    
    subgraph "Finalization Layer"
        project["17-project.sh"]
        json["18-opencode-json.sh"]
        finalize["19-finalize.sh"]
        update["20-autoupdate.sh"]
    end
    
    helpers --> core
    core --> sys
    core --> docker
    core --> chrome
    core --> zsh
    
    sys --> java
    sys --> node
    sys --> python
    sys --> go
    sys --> rust
    sys --> dotnet
    
    helpers --> opencode
    helpers --> mcp
    helpers --> chromadb
    helpers --> shokunin
    helpers --> sec
    helpers --> llm
    helpers --> rag
    
    core --> project
    project --> json
    json --> finalize
    finalize --> update
```

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Modular architecture** | Each language/tool isolated in its own module. Easy to add/remove/update. |
| **Progress tracking** | `~/.cache/opencode-setup/progress` records completed steps. Re-runs are idempotent. |
| **Adoptium API for Java** | GitHub-hosted CDN, reliable in WSL2 unlike sdkman.io |
| **npm pack cache for MCP** | `.tgz` files cached locally, survive re-runs |
| **All curl via _curl()** | 5 retries, exponential backoff, 24h cache |
| **All npm via _npm_install()** | npm pack → bun fallback |
| **WSL2 DNS fix** | Adds 8.8.8.8 + 1.1.1.1 to /etc/resolv.conf |
| **No secrets in code** | All API keys via CLI arguments only |
| **Bun binary paths for MCP** | Absolute paths to `~/.bun/bin/` instead of `npx -y`, instant cold start |
| **Auto-update via systemd** | topgrade runs weekly (Sun 04:00), unattended-upgrades for daily security |
| **Bootstrap time logging** | `tee` to `~/.cache/opencode-setup/setup-YYYYMMDD-HHMMSS.log` |
