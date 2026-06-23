# :fontawesome-solid-download: Getting Started

New to opencode_initializer? This guide walks you through everything — from zero to a fully working AI-enhanced development environment.

!!! info "Time estimate"
    A full install takes **15-30 minutes** depending on your internet connection and machine speed. Re-runs are faster (idempotent).

## :fontawesome-solid-circle-info: What You Need

### System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **OS** | Ubuntu 22.04+ / Debian 12 / WSL2 / Fedora 40+ | Ubuntu 24.04 LTS |
| **RAM** | 4 GB | 16 GB+ (for LLM features) |
| **Disk** | 10 GB free | 50 GB+ (with LLM models) |
| **Internet** | Broadband | Fast connection (many downloads) |
| **Shell** | bash 4.0+ | zsh (will be installed) |

### Before You Start

1. :fontawesome-solid-check: **Fresh OS install** recommended (or at least a clean user)
2. :fontawesome-solid-check: **Internet connection** — the script downloads lots of packages
3. :fontawesome-solid-check: **Sudo access** — you'll need to enter your password
4. :fontawesome-solid-check: **Review the script** — `curl -fsSL <url> | less` before piping to bash

## :fontawesome-solid-play: Installation

### Option 1: One-liner (easiest)

```bash
curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash
```

### Option 2: Clone and run (more control)

```bash
git clone https://github.com/AlexanderNarbaev/opencode_initializer.git ~/opencode_initializer
cd ~/opencode_initializer
bash setup.sh
```

### Option 3: Specific mode

```bash
# Health check only (no changes)
bash setup.sh --health

# Interactive — choose what to install
bash setup.sh --interactive

# New project only (skip system tools)
bash setup.sh --new ~/my-project

# Preview mode (dry-run)
bash setup.sh --dry-run

# Refresh tools, keep data
bash setup.sh --reinit
```

!!! warning "Windows Users (WSL2)"
    Before running, ensure WSL2 is properly configured. The script sets up:
    - DNS fix (8.8.8.8, 1.1.1.1)
    - Memory limits in `.wslconfig`
    - Mirrored networking mode
    - Chrome with `--no-sandbox` for WSL2

## :fontawesome-solid-eye: What Happens During Install

The script runs through these stages:

```mermaid
flowchart LR
    A[System Check] --> B[System Packages]
    B --> C[Docker]
    C --> D[Chrome]
    D --> E[ZSH]
    E --> F["Languages (8)"]
    F --> G[OpenCode CLI]
    G --> H["MCP + LSP (21+13)"]
    H --> I[ChromaDB]
    I --> J[LLM Tools]
    J --> K[Project Setup]
    K --> L[Finalize]
    L --> M[Done]
```

### Stage Details

| # | Stage | What it does | ~Time |
|---|-------|-------------|-------|
| 1 | **System Check** | Detects OS, package manager, architecture | 1s |
| 2 | **System Packages** | Installs build tools, curl, git, etc. | 3m |
| 3 | **Docker** | Docker Engine installation | 2m |
| 4 | **Chrome** | Google Chrome + ChromeDriver | 1m |
| 5 | **ZSH** | Zsh + Oh My Zsh + P10k + plugins | 2m |
| 6 | **Languages** | Java, Node, Python, Go, Rust, .NET, Zig | 10m |
| 7 | **OpenCode CLI** | OpenCode + Bun runtime | 1m |
| 8 | **MCP + LSP** | 21 MCP servers + 13 LSP servers | 5m |
| 9 | **ChromaDB** | Vector database + Muninn memory | 1m |
| 10 | **LLM Tools** | Ollama, vLLM, SGLang, Open WebUI | 5m |
| 11 | **Project Setup** | AGENTS.md, project structure | 1s |
| 12 | **Finalize** | PATH, git config, verification | 1m |

## :fontawesome-solid-check: After Install

### Verify Everything Works

```bash
# Run health diagnostics
bash ~/opencode_initializer/setup.sh --health

# Or use the dev CLI
dev health

# Check tool versions
dev version-check
```

### First Steps

1. **Restart your shell** or run `source ~/.zshrc`
2. **Set up git** (if not already):
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "you@example.com"
   ```
3. **Start using AI code generation**:
   ```bash
   opencode "Create a simple Go web server"
   ```
4. **Explore MCP servers** — they're already configured in `opencode.json`

### The `dev` CLI

After installation, a handy `dev` CLI tool is available:

```bash
dev health          # Full diagnostics (60+ checks)
dev version-check   # Compare installed vs latest versions
dev update          # Update all tools
dev list            # List installed components
dev install docker  # Install a new component
dev remove java     # Remove a component
dev config          # Edit setup config
dev autoupdate      # Run full system update (topgrade)
dev self-update     # Update setup.sh itself from GitHub
```

## :fontawesome-solid-triangle-exclamation: Common First-Time Issues

### "Permission denied" on curl|bash

Make sure you're not running as root. The script uses `sudo` internally where needed.

### WSL2: DNS not resolving

The script adds Google DNS (8.8.8.8, 1.1.1.1) automatically. If still broken:
```bash
sudo sh -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
```

### "Package not found" on non-Ubuntu systems

The script auto-detects your package manager. If it fails, install the equivalent packages manually and re-run.

### Chrome won't start in WSL2

Chrome is configured with `--no-sandbox` for WSL2. Use the `chrome-open` launcher:
```bash
chrome-open
```

## :fontawesome-solid-arrow-right: Next Steps

- [User Guide](../user-guide/) — day-to-day usage
- [Advanced Guide](../advanced/) — customization and WSL2 tuning
- [Architecture](../architecture/) — understand how it works
- [Reference](../reference/) — CLI and config reference
- [FAQ](../faq/) — common questions and answers
