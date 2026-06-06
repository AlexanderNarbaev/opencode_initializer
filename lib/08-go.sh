#!/usr/bin/env bash
# lib/08-go.sh — Go 1.24+ (STEP 6a)
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_GO"; then
  section "Go"
  if ! command -v go &>/dev/null; then
    GO_LATEST=$(curl -s --connect-timeout 10 https://go.dev/VERSION?m=text 2>/dev/null | head -1 | tr -d 'go \n' || echo "1.26.4")
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
    log "Go $(go version 2>/dev/null | cut -d' ' -f3) already installed"
  fi
  command -v go &>/dev/null && go env -w GOPROXY="${GOPROXY:-https://goproxy.io,direct}" 2>/dev/null || true
  _step_done step_go
fi
