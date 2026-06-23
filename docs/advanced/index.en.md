# Advanced Guide

Deep dive into customization, optimization, and advanced workflows.

## Custom Configuration

### Setup Config File

Persistent settings live in `~/.config/opencode-setup/setup.conf`:

```bash
# Edit config
dev config
```

### Custom ZSH

Add custom plugins, themes, and aliases to `~/.zshrc.local`:

```bash
# ~/.zshrc.local — not managed by the installer
export EDITOR=vim
alias k="kubectl"
alias tf="terraform"
```

### Custom opencode.json

```bash
# Regenerate opencode.json
bash setup.sh --fix-config

# Or edit manually
vim ~/opencode_initializer/opencode.json
```

## WSL2 Deep Dive

### .wslconfig Optimization

The installer creates `%USERPROFILE%\.wslconfig` on Windows:

```ini
[wsl2]
memory=8GB
processors=4
localhostForwarding=true
nestedVirtualization=false
networkingMode=mirrored
```

Adjust based on your hardware:

| RAM | Recommended memory= |
|-----|-------------------|
| 16 GB | 8 GB |
| 32 GB | 16 GB |
| 64 GB | 32 GB |

### DNS in WSL2

The installer adds Google DNS to `/etc/resolv.conf`. If using corporate DNS:

```bash
# Make resolv.conf persistent
sudo sh -c 'echo "[network]\ngenerateResolvConf = false" > /etc/wsl.conf'
sudo sh -c 'echo "nameserver 10.0.0.1" > /etc/resolv.conf'
```

### WSL2 File Performance

- Work inside the Linux filesystem (`~/projects/`), not `/mnt/c/`
- The installer sets `~/projects` as default project directory
- Cross-filesystem operations are 10-100x slower

## GPU Setup

### NVIDIA Drivers (Windows Host)

1. Install [NVIDIA drivers for WSL2](https://developer.nvidia.com/cuda/wsl)
2. Verify: `nvidia-smi` inside WSL2

### CUDA Toolkit

```bash
# Check CUDA
nvcc --version

# Install if missing
sudo apt install nvidia-cuda-toolkit
```

### GPU for Ollama

```bash
# Check GPU availability
ollama run llama3.2 "What GPU are you using?"

# Monitor GPU usage
nvidia-smi -l 1
```

### GPU Memory Limits

Limit Ollama GPU memory in `~/.ollama/config.toml`:

```toml
[gpu]
num_gpu = 1
main_gpu = 0
low_vram = false
```

## Docker Deep Dive

### Post-install Steps

```bash
# Add user to docker group (done by installer)
sudo usermod -aG docker $USER
newgrp docker

# Test
docker run hello-world
```

### Docker Compose

```bash
# Create a compose file
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  postgres:
    image: postgres:17
    environment:
      POSTGRES_PASSWORD: dev
    ports:
      - "5432:5432"
  redis:
    image: redis:7
    ports:
      - "6379:6379"
EOF

docker compose up -d
```

## LLM & RAG

### Ollama Model Management

```bash
# List installed models
ollama list

# Pull recommended models
ollama pull llama3.2      # 2 GB — general purpose
ollama pull codellama      # 3.8 GB — code generation
ollama pull deepseek-r1    # 4.7 GB — reasoning

# Remove unused models
ollama rm unused-model

# Update all models
ollama pull llama3.2
```

### Custom Ollama Modelfile

```bash
cat > Modelfile << 'EOF'
FROM llama3.2
SYSTEM "You are a senior Go developer. Always suggest idiomatic Go solutions."
PARAMETER temperature 0.3
EOF

ollama create go-expert -f Modelfile
ollama run go-expert
```

### Open WebUI

```bash
# Start services
systemctl --user start ollama
systemctl --user start open-webui

# Access at http://localhost:3000
# Default: no authentication (localhost only)

# Enable external access
# Edit /etc/systemd/system/open-webui.service
# Change --host 127.0.0.1 to --host 0.0.0.0
```

### RAG System

The optional RAG system (`21-rag.sh`) provides:
- Corporate knowledge assistant
- ETL pipeline + proxy + Qdrant + Gemma
- Document ingestion and semantic search

```bash
# Install RAG
bash setup.sh --interactive  # Select "RAG System"
```

## ChromaDB & Muninn

### Muninn — AI Memory

Muninn provides persistent memory for OpenCode sessions:

```bash
# Check Muninn status
systemctl --user status chromadb

# ChromaDB data location
ls ~/.cache/chromadb/
```

## Multiple Languages

### Switching Versions

| Language | Command |
|----------|---------|
| Node.js | `nvm install 22 && nvm use 22` |
| Java | `sdk use java 21.0.2-tem` |
| Go | `go install golang.org/dl/go1.25@latest && go1.25 download` |
| Python | `uv python install 3.13` |
| Rust | `rustup default stable` |
| .NET | `dotnet --list-sdks` |

### Language-specific Tips

#### Go
```bash
# GOPROXY for RU mirrors
export GOPROXY=https://goproxy.cn,direct

# Workspace
mkdir -p ~/go/{bin,src,pkg}
```

#### Python
```bash
# Create venv with uv
uv venv
source .venv/bin/activate

# Install packages
uv pip install requests
```

#### Node.js
```bash
# npm mirror for RU
npm config set registry https://registry.npmmirror.com
```

## CI/CD Integration

### GitHub Actions

Add to your project's workflow:

```yaml
- name: Setup Dev Environment
  run: |
    curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash -s -- --reinit
```

### Pre-commit Hooks

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

## Security

### Trivy — Container Scanner

```bash
# Scan an image
trivy image python:3.14

# Scan filesystem
trivy fs /
```

### Qodana — Code Quality

```bash
# Run analysis
qodana scan --project-dir ~/my-project
```

### Regular Updates

```bash
# Auto-update (runs weekly via systemd)
systemctl --user status opencode-topgrade.timer

# Manual update
dev autoupdate
```

## Troubleshooting Advanced

### Reset Everything

```bash
# Clear progress (forces reinstall)
rm ~/.cache/opencode-setup/progress

# Re-run
bash setup.sh --reinit
```

### Debug Mode

```bash
# Run with verbose output
bash -x setup.sh 2>&1 | tee debug.log

# Check the log
grep -i error debug.log
```

### Network Issues

```bash
# Test connectivity
_curl https://github.com

# Check mirrors
echo $GOPROXY
npm config get registry
pip config get global.index-url
```
