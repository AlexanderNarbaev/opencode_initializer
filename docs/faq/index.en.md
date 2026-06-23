# FAQ & Troubleshooting

## Installation

### Q: The install script fails with "Permission denied"
**A:** Make sure you have sudo access. The script runs as your user and uses `sudo` for system-level operations. Do NOT run the entire script as root.

### Q: Can I run the script multiple times?
**A:** Yes. The script is idempotent — it tracks completed steps in `~/.cache/opencode-setup/progress` and skips already-installed components.

### Q: How long does a full install take?
**A:** 15-30 minutes depending on internet speed and machine performance. The heaviest parts are LLM tools (Ollama models) and language compilers (Rust, .NET).

### Q: Can I skip certain components?
**A:** Use interactive mode: `bash setup.sh --interactive`. Or use `dev remove <component>` after install.

### Q: Do I need all API tokens?
**A:** No. Only provide tokens you want to use. The script works without any tokens — MCP servers that require tokens will be disabled.

## Languages & Tools

### Q: Why Java 25 and not LTS?
**A:** Java 25 is the latest stable release. The project targets latest versions for all languages. You can install a different version manually.

### Q: Can I change language versions after install?
**A:** Yes. Each language manager (nvm, sdkman, rustup, etc.) allows version switching. Use:
- Node: `nvm install 22`, `nvm use 22`
- Java: `sdk use java 21.0.2-tem`
- Go: `go install golang.org/dl/go1.25@latest && go1.25 download`
- Python: `uv python install 3.13`

### Q: Why is npm prefix set to `~/.local`?
**A:** To avoid permission issues with global npm packages. This is the XDG-compliant location.

## WSL2 Specific

### Q: Chrome won't start / crashes
**A:** Use `chrome-open` — it's a wrapper with `--no-sandbox` for WSL2 compatibility.

### Q: DNS not resolving
**A:** The script adds Google DNS automatically. If still broken:
```bash
sudo sh -c 'printf "nameserver 8.8.8.8\nnameserver 1.1.1.1\n" > /etc/resolv.conf'
```

### Q: Docker not starting
**A:** Ensure WSL2 integration is enabled in Docker Desktop. Or use the Docker Engine installation from the script.

### Q: Memory/CPU issues
**A:** The script configures `.wslconfig` with limits. Adjust:
```ini
[wsl2]
memory=8GB
processors=4
```

## MCP & LSP

### Q: MCP servers don't start / "command not found"
**A:** MCP servers use absolute paths to `~/.bun/bin/`. Ensure Bun is installed:
```bash
curl -fsSL https://bun.sh/install | bash
```

### Q: Can I add custom MCP servers?
**A:** Yes. Edit `opencode.json` directly or use `dev config`.

### Q: LSP server not working in my editor
**A:** LSP servers are primarily configured for OpenCode. For VS Code/Vim/Emacs, you may need additional editor-specific configuration.

## AI / LLM

### Q: Ollama models take forever to download
**A:** Models are large (4-27 GB). Download only what you need:
```bash
ollama pull llama3.2    # 2 GB
ollama pull codellama   # 3.8 GB
ollama pull deepseek-r1 # 4.7 GB
```

### Q: GPU not detected for Ollama
**A:** Ensure NVIDIA drivers + CUDA toolkit are installed:
```bash
nvidia-smi  # Should show GPU info
```

### Q: Open WebUI not starting
**A:** It requires Ollama to be running first. Start Ollama:
```bash
systemctl --user start ollama
# or
ollama serve
```

## Updates & Maintenance

### Q: How do I update all tools?
**A:** 
```bash
dev update       # Update dev tools
dev autoupdate   # Full system update via topgrade
```

### Q: Auto-update is enabled — how do I check?
**A:**
```bash
systemctl --user status opencode-topgrade.timer
systemctl --user list-timers
```

### Q: How do I completely uninstall?
**A:** There's no automatic uninstall. The script installs tools to standard locations. Remove manually:
```bash
# Remove project
rm -rf ~/opencode_initializer
# Remove caches
rm -rf ~/.cache/opencode-setup
# Remove configs
rm -rf ~/.config/opencode-setup
rm -rf ~/.config/opencode
# Tools remain in their standard locations
```

## Configuration

### Q: Where is the config file?
**A:** `~/.config/opencode-setup/setup.conf`

### Q: How do I regenerate opencode.json?
**A:**
```bash
bash setup.sh --fix-config
```

### Q: How do I fix .zshrc?
**A:**
```bash
bash setup.sh --fix-zshrc
```

## Getting Help

- :fontawesome-brands-github: [GitHub Issues](https://github.com/AlexanderNarbaev/opencode_initializer/issues)
- :fontawesome-solid-book: [Full Documentation](https://alexandernarbaev.github.io/opencode_initializer/)
- :fontawesome-solid-code: [Source Code](https://github.com/AlexanderNarbaev/opencode_initializer)
