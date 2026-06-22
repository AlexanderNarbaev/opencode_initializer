#!/usr/bin/env bash
# lib/03-chrome.sh — Google Chrome for Playwright (STEP 2b)
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_CHROME"; then
  section "Google Chrome"

  if command -v google-chrome-stable &>/dev/null; then
    log "Google Chrome $(google-chrome-stable --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' || true) already installed"
  else
    CHROME_KEY_URL="https://dl.google.com/linux/linux_signing_key.pub"
    sudo mkdir -p /usr/share/keyrings 2>/dev/null || true
    if ! curl -fsSL --connect-timeout 10 "$CHROME_KEY_URL" 2>/dev/null | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg 2>/dev/null; then
      sudo curl -fsSL --connect-timeout 10 "$CHROME_KEY_URL" 2>/dev/null | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg 2>/dev/null || true
    fi
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | \
      sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null 2>&1 || true
    sudo apt-get update -qq 2>/dev/null || true
    sudo apt-get install -y -qq google-chrome-stable 2>/dev/null && log "Google Chrome installed" || warn "Chrome install failed"
    command -v chromedriver &>/dev/null || sudo apt-get install -y -qq google-chromedriver 2>/dev/null || sudo apt-get install -y -qq chromium-chromedriver 2>/dev/null || true
  fi

  IS_WSL=false
  grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=true
  grep -qi wsl /proc/version 2>/dev/null && IS_WSL=true

  if ! grep -q "chrome-open()" ~/.zshrc 2>/dev/null; then
    cat >> ~/.zshrc << 'CHROMEOF'

# ── Google Chrome launcher (WSL2-aware, remote debugging enabled) ──
chrome-open() {
  local port="${1:-9222}"
  local profile="${2:-$HOME/.config/google-chrome/opencode}"
  local chrome_bin="$(which google-chrome-stable 2>/dev/null || which google-chrome 2>/dev/null || echo '')"
  [ -z "$chrome_bin" ] && { echo "[!] google-chrome not found"; return 1; }

  mkdir -p "$profile"

  local flags=(
    "--remote-debugging-port=$port"
    "--user-data-dir=$profile"
    "--disable-background-networking"
    "--disable-sync"
    "--no-first-run"
    "--no-default-browser-check"
    "--disable-features=TranslateUI"
    "--disable-ipc-flooding-protection"
    "--disable-renderer-backgrounding"
    "--disable-background-timer-throttling"
    "--disable-client-side-phishing-detection"
    "--disable-popup-blocking"
    "--disable-prompt-on-repost"
    "--enable-automation"
    "--password-store=basic"
    "--use-mock-keychain"
  )

  if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
    flags+=("--no-sandbox")
  fi

  nohup "$chrome_bin" "${flags[@]}" >/dev/null 2>&1 &
  local pid=$!
  sleep 1
  if kill -0 "$pid" 2>/dev/null; then
    echo "[✓] Chrome started (PID $pid, CDP port $port)"
    echo "    Connect: http://127.0.0.1:$port"
  else
    echo "[!] Chrome failed to start — try: google-chrome-stable --no-sandbox"
  fi
}
CHROMEOF
    log "chrome-open function added to .zshrc"
  fi

  if ! grep -q "alias chrome=" ~/.zshrc 2>/dev/null; then
    echo 'alias chrome="chrome-open 9222"' >> ~/.zshrc
    log "chrome alias added to .zshrc"
  fi

  mkdir -p "$HOME/.local/bin"
  cat > "$HOME/.local/bin/chrome-open" << 'CHROMEBIN'
#!/usr/bin/env bash
# Google Chrome Remote Debugging Launcher
set -euo pipefail
PORT="${1:-9222}"
PROFILE="${2:-$HOME/.config/google-chrome/opencode}"
CHROME_BIN="$(which google-chrome-stable 2>/dev/null || which google-chrome 2>/dev/null || echo '')"
[ -z "$CHROME_BIN" ] && { echo "[!] google-chrome not found"; exit 1; }
mkdir -p "$PROFILE"
FLAGS=(
  "--remote-debugging-port=$PORT" "--user-data-dir=$PROFILE"
  "--disable-background-networking" "--disable-sync" "--no-first-run"
  "--no-default-browser-check" "--disable-features=TranslateUI"
  "--disable-ipc-flooding-protection" "--disable-renderer-backgrounding"
  "--disable-background-timer-throttling" "--disable-client-side-phishing-detection"
  "--disable-popup-blocking" "--disable-prompt-on-repost"
  "--enable-automation" "--password-store=basic" "--use-mock-keychain"
)
grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null && FLAGS+=("--no-sandbox")
nohup "$CHROME_BIN" "${FLAGS[@]}" >/dev/null 2>&1 &
sleep 1
if kill -0 $! 2>/dev/null; then
  echo "[✓] Chrome started (CDP port $PORT) — http://127.0.0.1:$PORT"
else
  echo "[!] Chrome failed to start"
  exit 1
fi
CHROMEBIN
  chmod +x "$HOME/.local/bin/chrome-open"
  log "chrome-open script installed to ~/.local/bin/chrome-open"

  _step_done step_chrome
fi
