#!/usr/bin/env bash
# lib/08-go.sh — Go (latest, STEP 6a)
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_GO"; then
  section "Go"
  if ! command -v go &>/dev/null; then
    GO_LATEST=$(curl -s --connect-timeout 10 --retry 3 --retry-delay 2 https://go.dev/VERSION?m=text 2>/dev/null | head -1 | tr -d 'go \n' || echo "1.26.5")
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
      sudo apt-get install -y -qq golang-go 2>/dev/null && log "Go from apt" || warn "Go unavailable — install manually from https://go.dev/dl/"
    fi
  else
    GO_CURRENT=$(go version 2>/dev/null | grep -oP 'go\K[0-9]+\.[0-9]+' | head -1 || echo "0")
    GO_MINOR=$(echo "$GO_CURRENT" | cut -d. -f2)
    if [ "$GO_MINOR" -lt 26 ] 2>/dev/null; then
      GO_LATEST=$(curl -s --connect-timeout 10 --retry 3 --retry-delay 2 https://go.dev/VERSION?m=text 2>/dev/null | head -1 | tr -d 'go \n' || echo "1.26.5")
      info "Go ${GO_CURRENT} is outdated, upgrading to ${GO_LATEST}..."
      GO_ARCH="${GO_ARCH:-linux-amd64}"
      GO_TAR="/tmp/go${GO_LATEST}.${GO_ARCH}.tar.gz"
      if _curl "https://go.dev/dl/go${GO_LATEST}.${GO_ARCH}.tar.gz" "$GO_TAR" 2>/dev/null; then
        sudo rm -rf /usr/local/go 2>/dev/null || true
        sudo tar -C /usr/local -xzf "$GO_TAR" && log "Go upgraded to ${GO_LATEST}" || warn "Go upgrade failed"
        rm -f "$GO_TAR"
        export PATH="/usr/local/go/bin:$PATH"
      fi
      # If direct download failed but version is still old, try apt
      if ! /usr/local/go/bin/go version &>/dev/null; then
        _sudo add-apt-repository -y ppa:longsleep/golang-backports 2>/dev/null || true
        _sudo apt-get update -qq 2>/dev/null || true
        _sudo apt-get install -y -qq golang-go 2>/dev/null && log "Go upgraded via apt" || true
        export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
        hash -r 2>/dev/null || true
      fi
    else
      log "Go $(go version 2>/dev/null | cut -d' ' -f3) already installed"
    fi
  fi
  if command -v go &>/dev/null; then
    current_proxy=$(go env GOPROXY 2>/dev/null || true)
    if [ -z "$current_proxy" ] || [ "$current_proxy" = "https://proxy.golang.org,direct" ]; then
      go env -w GOPROXY="${GOPROXY:-https://goproxy.io,direct}" 2>/dev/null || true
    fi
  fi
  _step_done step_go
fi
