# Phase 0: Stabilization — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Починить всё, что задокументировано в opencode_initializer v1.1.0, но не работает на машине.

**Architecture:** 8 независимых задач. Каждая чинит конкретный сломанный компонент: Go v1.22.5→v1.26, Zig 0.15.1, Ollama-модели, Muninn, CodeGraph, LiteLLM, autoupdate systemd, сессионная память. Ничего не добавляем нового — только приводим в соответствие с тем, что уже описано в AGENTS.md и src/lib/*.sh.

**Tech Stack:** Bash, Go, Zig, Ollama, pipx, systemd, Docker

## Global Constraints

- `bash -n` passes on all modified `.sh` files
- Все команды используют `|| true` для толерантности к ошибкам
- ShellCheck passes on all modified `.sh` files
- Существующие тесты продолжают проходить
- `TOTAL_STEPS` не меняется (Phase 0 не добавляет шагов)
- Никаких новых модулей — только правки существующих
- Все изменения идемпотентны (можно перезапускать)
- Версия `SCRIPT_VERSION=v1.1.0` в `00-core.sh` не меняется

---

### Task 0.1: Fix Go upgrade from 1.22.5 to 1.26

**Files:**
- Modify: `src/lib/08-go.sh:7-18`
- Modify: `src/modes/upgrade.sh`

**Interfaces:**
- Consumes: `MODE`, `GOPROXY`, `GITHUB_MIRROR`, `_curl()` from helpers.sh
- Produces: Go binary at `/usr/local/go/bin/go` with version 1.26.x

**Problem:** Go 1.22.5 не обновляется при повторном прогоне, потому что проверка `command -v go` проходит (Go установлен, но старая версия). Нужно добавить версионную проверку.

- [ ] **Step 1: Add version check to 08-go.sh**

Replace the existing install block (lines 7-20) with version-aware logic:

```bash
# In src/lib/08-go.sh, replace lines 7-20:
if ! command -v go &>/dev/null; then
  GO_LATEST=$(curl -s --connect-timeout 10 --retry 3 --retry-delay 2 https://go.dev/VERSION?m=text 2>/dev/null | head -1 | tr -d 'go \n' || echo "1.26.4")
  info "Latest Go: ${GO_LATEST}"
  GO_ARCH="${GO_ARCH:-linux-amd64}"
  GO_TAR="/tmp/go${GO_LATEST}.${GO_ARCH}.tar.gz"
  if _curl "https://go.dev/dl/go${GO_LATEST}.${GO_ARCH}.tar.gz" "$GO_TAR" 2>/dev/null; then
    sudo rm -rf /usr/local/go 2>/dev/null || true
    sudo tar -C /usr/local -xzf "$GO_TAR" && log "Go ${GO_LATEST} installed" || warn "Go tar extraction failed"
    rm -f "$GO_TAR"
    export PATH="/usr/local/go/bin:$PATH"
  else
    warn "Go download failed — trying apt fallback"
    sudo apt-get install -y -qq golang-go 2>/dev/null && log "Go from apt" || warn "Go unavailable"
  fi
else
  GO_CURRENT=$(go version 2>/dev/null | grep -oP 'go\K[0-9]+\.[0-9]+' | head -1 || echo "0")
  GO_MINOR=$(echo "$GO_CURRENT" | cut -d. -f2)
  if [ "$GO_MINOR" -lt 26 ] 2>/dev/null; then
    GO_LATEST=$(curl -s --connect-timeout 10 --retry 3 --retry-delay 2 https://go.dev/VERSION?m=text 2>/dev/null | head -1 | tr -d 'go \n' || echo "1.26.4")
    info "Go ${GO_CURRENT} is outdated, upgrading to ${GO_LATEST}..."
    GO_ARCH="${GO_ARCH:-linux-amd64}"
    GO_TAR="/tmp/go${GO_LATEST}.${GO_ARCH}.tar.gz"
    if _curl "https://go.dev/dl/go${GO_LATEST}.${GO_ARCH}.tar.gz" "$GO_TAR" 2>/dev/null; then
      sudo rm -rf /usr/local/go 2>/dev/null || true
      sudo tar -C /usr/local -xzf "$GO_TAR" && log "Go upgraded to ${GO_LATEST}" || warn "Go upgrade failed"
      rm -f "$GO_TAR"
      export PATH="/usr/local/go/bin:$PATH"
    else
      warn "Go download failed"
    fi
  else
    log "Go $(go version 2>/dev/null | cut -d' ' -f3) already installed"
  fi
fi
```

- [ ] **Step 2: Add Go upgrade to upgrade.sh mode**

In `src/modes/upgrade.sh`, after the Rust upgrade block, add:

```bash
# ── Go version upgrade ─────────────────────────────────────────────
if command -v go &>/dev/null; then
  GO_CURRENT=$(go version 2>/dev/null | grep -oP 'go\K[0-9]+\.[0-9]+' | head -1 || echo "0")
  GO_MINOR=$(echo "$GO_CURRENT" | cut -d. -f2)
  GO_LATEST=$(curl -s --connect-timeout 10 --retry 3 https://go.dev/VERSION?m=text 2>/dev/null | head -1 | tr -d 'go \n' || echo "1.26.4")
  if [ "$GO_MINOR" -lt 26 ] 2>/dev/null; then
    section "Go ${GO_CURRENT} → ${GO_LATEST}"
    GO_ARCH="linux-amd64"
    GO_TAR="/tmp/go${GO_LATEST}.${GO_ARCH}.tar.gz"
    _curl "https://go.dev/dl/go${GO_LATEST}.${GO_ARCH}.tar.gz" "$GO_TAR" 2>/dev/null && \
      sudo rm -rf /usr/local/go 2>/dev/null && \
      sudo tar -C /usr/local -xzf "$GO_TAR" && \
      log "Go ${GO_LATEST}" || warn "Go upgrade failed"
    rm -f "$GO_TAR"
  else
    log "Go ${GO_CURRENT} (latest)"
  fi
fi
```

- [ ] **Step 3: Run the fix directly on the machine**

```bash
# Manually upgrade Go now:
GO_LATEST=$(curl -s --connect-timeout 10 --retry 3 https://go.dev/VERSION?m=text 2>/dev/null | head -1 | tr -d 'go \n' || echo "1.26.4")
echo "Latest Go: $GO_LATEST"
GO_ARCH="linux-amd64"
sudo rm -rf /usr/local/go
curl -fsSL "https://go.dev/dl/go${GO_LATEST}.${GO_ARCH}.tar.gz" -o /tmp/go.tar.gz && \
  sudo tar -C /usr/local -xzf /tmp/go.tar.gz && \
  go version && \
  rm /tmp/go.tar.gz && \
  echo "Go upgraded to $GO_LATEST"
```

- [ ] **Step 4: Verify**

```bash
go version
# Expected: go version go1.26.x linux/amd64
```

- [ ] **Step 5: Commit**

```bash
git add src/lib/08-go.sh src/modes/upgrade.sh
git commit -m "fix: Go version-aware upgrade (1.22→1.26)"
```

---

### Task 0.2: Install Zig 0.15.1

**Files:**
- Modify: `src/lib/05-java.sh:55-72` (Zig install block)

**Interfaces:**
- Consumes: `MODE`, `ZIG_MIRROR`
- Produces: Zig binary at `/usr/local/bin/zig`

**Problem:** Zig не установлен на машине. Модуль 05-java.sh имеет код установки Zig 0.15.1, но не сработал при первом прогоне (возможно, URL был недоступен).

- [ ] **Step 1: Check Zig installation code in 05-java.sh**

Read current Zig block at lines 55-72. ZIG_VER should be `0.15.1` per AGENTS.md.

- [ ] **Step 2: Install Zig directly on the machine**

```bash
ZIG_VER="0.15.1"
ZIG_URL="https://ziglang.org/download/${ZIG_VER}/zig-linux-x86_64-${ZIG_VER}.tar.xz"
ZIG_DIR="/usr/local/zig-${ZIG_VER}"

# Try main URL first
if curl -fsSL --connect-timeout 10 --retry 3 "$ZIG_URL" -o /tmp/zig.tar.xz; then
  sudo mkdir -p "$ZIG_DIR"
  sudo tar -xJf /tmp/zig.tar.xz -C "$ZIG_DIR" --strip-components=1 && \
    sudo ln -sf "$ZIG_DIR/zig" /usr/local/bin/zig && \
    zig version && \
    echo "Zig installed"
  rm -f /tmp/zig.tar.xz
else
  # Fallback: try apt
  sudo apt-get install -y -qq zig 2>/dev/null && zig version && echo "Zig installed via apt" || echo "Zig unavailable"
fi
```

- [ ] **Step 3: Verify Zig version is exactly 0.15.1 in source**

```bash
grep "ZIG_VER=" src/lib/05-java.sh
# Expected: ZIG_VER="0.15.1"
```

If not, fix to `0.15.1`.

- [ ] **Step 4: Verify**

```bash
zig version
# Expected: 0.15.1  (or whatever apt provides)
```

- [ ] **Step 5: Commit**

```bash
git add src/lib/05-java.sh
git commit -m "fix: Zig 0.15.1 installation hardening"
```

---

### Task 0.3: Pull Ollama models (qwen3:14b, qwen3:1.8b, llava:7b)

**Files:**
- No source changes needed (16-llm.sh already has pull commands at lines 94-96, 206-208)
- The problem: pulls run in background with `&` and may have failed silently

**Interfaces:**
- Consumes: Ollama daemon running
- Produces: Models available via `ollama list`

**Problem:** 16-llm.sh запускает `ollama pull ... &` в фоне. К моменту проверки в health.sh или 19-finalize.sh модели ещё не загружены. А на этой машине они вообще не загрузились (0 моделей).

- [ ] **Step 1: Pull models directly**

```bash
# Start ollama if not running
systemctl --user start ollama 2>/dev/null || ollama serve &>/dev/null &
sleep 3

# Pull models synchronously
echo "Pulling qwen3:1.8b (~1.2GB)..."
ollama pull qwen3:1.8b

echo "Pulling qwen3:14b (~8.5GB)..."
ollama pull qwen3:14b

echo "Pulling llava:7b (~4.5GB)..."
ollama pull llava:7b

echo "Pulling mxbai-embed-large (embeddings)..."
ollama pull mxbai-embed-large

# Verify
ollama list
```

- [ ] **Step 2: Fix 16-llm.sh to make pulls synchronous and verified**

Replace background pulls at lines 94-96:

```bash
# Before (broken):
ollama pull qwen3:14b 2>/dev/null & log "Ollama: pulling qwen3:14b (background)"
ollama pull qwen3:1.8b 2>/dev/null & log "Ollama: pulling qwen3:1.8b (background)"

# After (synchronous with timeout):
ollama pull qwen3:1.8b 2>/dev/null || warn "Ollama: qwen3:1.8b pull failed"
ollama pull qwen3:14b 2>/dev/null || warn "Ollama: qwen3:14b pull failed"
```

And at lines 206-208 for llava:

```bash
# Before:
ollama pull llava:7b 2>/dev/null & log "Ollama: pulling llava:7b (background)"

# After:
ollama pull llava:7b 2>/dev/null || warn "Ollama: llava:7b pull failed"
```

- [ ] **Step 3: Add ollama model verification to health.sh**

In `src/modes/health.sh`, after the existing `_check "llava (vision)"`, add:

```bash
_check "qwen3:1.8b" "ollama list 2>/dev/null | grep -q qwen3:1.8b"
_check "qwen3:14b"  "ollama list 2>/dev/null | grep -q qwen3:14b"
_check "mxbai-embed" "ollama list 2>/dev/null | grep -q mxbai-embed"
```

- [ ] **Step 4: Verify**

```bash
ollama list
# Expected: qwen3:1.8b, qwen3:14b, llava:7b, mxbai-embed-large
```

- [ ] **Step 5: Commit**

```bash
git add src/lib/16-llm.sh src/modes/health.sh
git commit -m "fix: synchronous Ollama model pulls + health verification"
```

---

### Task 0.4: Install and initialize Muninn

**Files:**
- Modify: `src/lib/12-mcp-lsp.sh:48-56` (Muninn install block)

**Interfaces:**
- Consumes: pipx, Python 3.14
- Produces: `muninn-remembers` binary, Muninn skills in opencode

**Problem:** Muninn не установлен (`~/.local/share/muninn/` не существует). Код в 12-mcp-lsp.sh пытается установить `muninn-remembers` через pipx, но мог упасть молча.

- [ ] **Step 1: Install Muninn directly**

```bash
# Install Muninn
pipx install muninn-remembers 2>&1

# Verify binary
which muninn-remembers
muninn-remembers --help 2>&1 | head -5

# Install opencode skills for Muninn
muninn-remembers install opencode 2>&1

# Initialize Muninn for current project
cd /home/alexandr-narbaev/Projects/opencode_initializer
muninn-remembers init 2>&1 || echo "muninn init skipped (may already be initialized)"

# Check storage
ls -la ~/.local/share/muninn/ 2>&1
```

- [ ] **Step 2: Fix Muninn install in 12-mcp-lsp.sh for reliability**

Replace lines 48-56:

```bash
# Before:
if ! command -v muninn-remembers &>/dev/null; then
  _retry 3 "Muninn pipx install" pipx install muninn-remembers 2>/dev/null || true
else
  pipx install --force muninn-remembers 2>/dev/null || true
fi
if command -v muninn-remembers &>/dev/null; then
  muninn-remembers install opencode 2>/dev/null || warn "Muninn: skills install failed"
fi

# After:
if ! command -v muninn-remembers &>/dev/null; then
  _retry 3 "Muninn pipx install" pipx install muninn-remembers 2>/dev/null && log "Muninn installed" || warn "Muninn: install failed"
else
  log "Muninn $(muninn-remembers --version 2>/dev/null || echo 'installed')"
fi
if command -v muninn-remembers &>/dev/null; then
  muninn-remembers install opencode 2>/dev/null && log "Muninn: opencode skills" || warn "Muninn: skills install failed"
  # Initialize for current project if PROJECT_DIR is set
  if [ -n "${PROJECT_DIR:-}" ] && [ -d "$PROJECT_DIR" ]; then
    cd "$PROJECT_DIR" && muninn-remembers init 2>/dev/null || true
  fi
fi
```

- [ ] **Step 3: Add Muninn verification to health.sh and 19-finalize.sh**

In `src/modes/health.sh`, add to memory chain section:

```bash
_check "Muninn binary" "command -v muninn-remembers &>/dev/null"
_check "Muninn storage" "[ -d ~/.local/share/muninn ]"
_check "Muninn opencode" "muninn-remembers list 2>/dev/null | grep -q opencode"
```

In `src/lib/19-finalize.sh`, add to verification section:

```bash
_check "Muninn" "command -v muninn-remembers &>/dev/null"
```

- [ ] **Step 4: Verify**

```bash
muninn-remembers --version
ls ~/.local/share/muninn/
```

- [ ] **Step 5: Commit**

```bash
git add src/lib/12-mcp-lsp.sh src/modes/health.sh src/lib/19-finalize.sh
git commit -m "fix: Muninn install reliability + verification checks"
```

---

### Task 0.5: Initialize CodeGraph for current project

**Files:**
- Modify: `src/lib/12-mcp-lsp.sh` (add codegraph init after install)
- Modify: `src/lib/18-opencode-json.sh` (conditional codegraph MCP enable)

**Interfaces:**
- Consumes: `opencode-codegraph@0.1.37` (npm package), `codegraph` binary
- Produces: `.codegraph/` directory in project root, indexed codebase

**Problem:** Плагин `opencode-codegraph` установлен, но `.codegraph/` не создан — CodeGraph не индексирует код.

- [ ] **Step 1: Initialize CodeGraph directly**

```bash
cd /home/alexandr-narbaev/Projects/opencode_initializer
codegraph init 2>&1
# This creates .codegraph/ directory and starts indexing
ls -la .codegraph/ 2>&1
```

- [ ] **Step 2: Add auto-initialization to 12-mcp-lsp.sh**

After the npm install block for opencode-codegraph (line ~107), add:

```bash
# Initialize CodeGraph for current project if PROJECT_DIR is set
if command -v codegraph &>/dev/null && [ -n "${PROJECT_DIR:-}" ] && [ -d "$PROJECT_DIR" ]; then
  if [ ! -d "$PROJECT_DIR/.codegraph" ]; then
    cd "$PROJECT_DIR" && codegraph init 2>/dev/null && log "CodeGraph: initialized" || warn "CodeGraph: init failed"
  else
    log "CodeGraph: already initialized"
  fi
fi
```

- [ ] **Step 3: Make codegraph MCP conditional on index existence**

In `src/lib/18-opencode-json.sh`, the `codegraph` MCP server entry should check:

```python
# Check if codegraph is initialized before enabling the MCP
codegraph_initialized = False
if PROJECT_DIR and os.path.isdir(os.path.join(PROJECT_DIR, '.codegraph')):
    codegraph_initialized = True

# Only add codegraph MCP if initialized
if codegraph_initialized:
    mcp_servers["codegraph"] = {
        "type": "local",
        "command": "codegraph",
        "args": ["serve", "--mcp"]
    }
```

- [ ] **Step 4: Verify**

```bash
ls -la /home/alexandr-narbaev/Projects/opencode_initializer/.codegraph/
codegraph status 2>&1
```

- [ ] **Step 5: Commit**

```bash
git add src/lib/12-mcp-lsp.sh src/lib/18-opencode-json.sh
git commit -m "fix: CodeGraph auto-init + conditional MCP enable"
```

---

### Task 0.6: Install LiteLLM and configure systemd service

**Files:**
- Modify: `src/lib/25-litellm.sh` (fix install + config generation)
- Create: `~/.config/litellm/config.yaml` (generated by script)

**Interfaces:**
- Consumes: pipx/pip, Python, Ollama models
- Produces: `litellm` binary, `~/.config/litellm/config.yaml`, `litellm.service`

**Problem:** LiteLLM не установлен. 25-litellm.sh существует, но на этой машине бинарник `litellm` не найден.

- [ ] **Step 1: Install LiteLLM directly**

```bash
pipx install litellm 2>&1

# Verify
which litellm
litellm --help 2>&1 | head -5

# Generate config
mkdir -p ~/.config/litellm

OLLAMA_MODELS="qwen3:1.8b"
if command -v ollama &>/dev/null; then
  DETECTED=$(ollama list 2>/dev/null | awk 'NR>1{print $1}' | tr '\n' ',' | sed 's/,$//')
  [ -n "$DETECTED" ] && OLLAMA_MODELS="$DETECTED"
fi

cat > ~/.config/litellm/config.yaml << YAML
general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
  database_url: os.environ/LITELLM_DATABASE_URL

model_list:
YAML

# Add detected Ollama models
for model in $(echo "$OLLAMA_MODELS" | tr ',' ' '); do
  cat >> ~/.config/litellm/config.yaml << YAML
  - model_name: ollama/$model
    litellm_params:
      model: ollama/$model
      api_base: http://localhost:11434
YAML
done

echo "LiteLLM config written to ~/.config/litellm/config.yaml"
cat ~/.config/litellm/config.yaml
```

- [ ] **Step 2: Create systemd user service for LiteLLM**

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/litellm.service << 'SVC'
[Unit]
Description=LiteLLM Proxy — OpenAI-compatible local API gateway
After=network.target

[Service]
Type=simple
ExecStart=%h/.local/bin/litellm --config %h/.config/litellm/config.yaml --port 4000
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
SVC

systemctl --user daemon-reload
systemctl --user enable litellm.service
systemctl --user start litellm.service

# Verify
sleep 3
curl -s http://localhost:4000/health 2>&1
```

- [ ] **Step 3: Fix 25-litellm.sh for reliability**

Read current file and verify install commands are correct. The critical fix: ensure `pipx ensurepath` runs before install, and add service creation that matches the code above.

- [ ] **Step 4: Verify**

```bash
systemctl --user status litellm.service
curl -s http://localhost:4000/health
```

- [ ] **Step 5: Commit**

```bash
git add src/lib/25-litellm.sh
git commit -m "fix: LiteLLM install + systemd service hardening"
```

---

### Task 0.7: Fix autoupdate systemd service

**Files:**
- Modify: `src/lib/20-autoupdate.sh:27-67` (systemd service definition)

**Interfaces:**
- Consumes: topgrade binary, systemctl --user
- Produces: working `opencode-update.service` + `opencode-update.timer`

**Problem:** `opencode-update.service` в состоянии failed. Причина: topgrade запускается без флага `--yes`, либо команда `ExecStart` ссылается на пути которые не резолвятся.

- [ ] **Step 1: Diagnose current failure**

```bash
systemctl --user status opencode-update.service
journalctl --user -u opencode-update.service --no-pager -n 30
```

- [ ] **Step 2: Fix and restart the service**

```bash
# Reinstall the service definition
cat > ~/.config/systemd/user/opencode-update.service << 'SVC'
[Unit]
Description=OpenCode Dev Machine Weekly Auto-Update
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStartPre=/bin/mkdir -p %h/.cache/opencode-setup
ExecStart=/bin/sh -c 'export PATH="$HOME/.cargo/bin:$HOME/.local/bin:/usr/local/bin:$PATH"; if command -v topgrade >/dev/null 2>&1; then topgrade --yes --no-retry --skip-notify 2>&1; else echo "topgrade not found" >&2; fi'
ExecStartPost=/bin/bash -c 'echo "$(date -Iseconds) topgrade completed" >> %h/.cache/opencode-setup/update.log'
StandardOutput=journal
StandardError=journal
TimeoutStartSec=7200

[Install]
WantedBy=default.target
SVC

systemctl --user daemon-reload
systemctl --user reset-failed opencode-update.service 2>/dev/null || true
systemctl --user reenable opencode-update.timer 2>/dev/null || true
systemctl --user start opencode-update.timer
systemctl --user status opencode-update.timer
```

Key fix: `ExecStart` теперь использует `command -v` вместо жёстких путей и экспортирует PATH с cargo/local/bin.

- [ ] **Step 3: Fix source module 20-autoupdate.sh**

Update the service template at lines 31-47 to match the fix above (add `PATH` export, use `command -v` instead of hardcoded paths, add `TimeoutStartSec`).

- [ ] **Step 4: Verify**

```bash
systemctl --user status opencode-update.timer
systemctl --user list-timers | grep opencode
```

- [ ] **Step 5: Commit**

```bash
git add src/lib/20-autoupdate.sh
git commit -m "fix: autoupdate systemd service — PATH + resilience"
```

---

### Task 0.8: Fix session memory (create sessions directory)

**Files:**
- Modify: `src/lib/19-finalize.sh` (add sessions dir creation)
- Modify: `src/lib/17-project.sh` (ensure sessions path in project setup)

**Interfaces:**
- Consumes: PROJECT_DIR, HOME
- Produces: `~/.config/opencode/sessions/` directory for session persistence

**Problem:** Сессионная память не работает — директория `~/.config/opencode/sessions/` не существует. OpenCode не может сохранять сессии.

- [ ] **Step 1: Create sessions directory directly**

```bash
mkdir -p ~/.config/opencode/sessions
ls -la ~/.config/opencode/sessions/
```

- [ ] **Step 2: Add session dir creation to 19-finalize.sh**

After the PATH persistence block, add:

```bash
# Session memory: ensure sessions directory exists
mkdir -p "$HOME/.config/opencode/sessions"
chmod 700 "$HOME/.config/opencode/sessions"
log "session memory: $HOME/.config/opencode/sessions ready"
```

- [ ] **Step 3: Add session directory to project setup in 17-project.sh**

After the directory creation block (lines 13-19), add sessions dir for project-local sessions:

```bash
# Ensure sessions directory for project-local session memory
mkdir -p "$HOME/.config/opencode/sessions"
```

- [ ] **Step 4: Add session verification to health.sh**

```bash
_check "Session dir" "[ -d ~/.config/opencode/sessions ]"
_check "Session writable" "[ -w ~/.config/opencode/sessions ]"
```

- [ ] **Step 5: Verify**

```bash
ls -la ~/.config/opencode/sessions/
# After next opencode run, check if session files appear:
# ls -la ~/.config/opencode/sessions/
```

- [ ] **Step 6: Commit**

```bash
git add src/lib/19-finalize.sh src/lib/17-project.sh src/modes/health.sh
git commit -m "fix: session memory directory creation + health checks"
```

---

## Execution Summary

| Task | Files Modified | Independent? | Manual Action Needed? |
|------|---------------|-------------|----------------------|
| 0.1 Go | `08-go.sh`, `upgrade.sh` | Yes | No |
| 0.2 Zig | `05-java.sh` | Yes | No |
| 0.3 Ollama | `16-llm.sh`, `health.sh` | Yes | Pull models (~14GB download) |
| 0.4 Muninn | `12-mcp-lsp.sh`, `health.sh`, `19-finalize.sh` | Yes | No |
| 0.5 CodeGraph | `12-mcp-lsp.sh`, `18-opencode-json.sh` | Yes | `codegraph init` |
| 0.6 LiteLLM | `25-litellm.sh` | Yes | No |
| 0.7 Autoupdate | `20-autoupdate.sh` | Yes | No |
| 0.8 Sessions | `19-finalize.sh`, `17-project.sh`, `health.sh` | Yes | No |

All 8 tasks are independent — can be executed in any order.
