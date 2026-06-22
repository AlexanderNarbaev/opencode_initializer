#!/usr/bin/env bash
# lib/10-dotnet.sh — .NET 10 (STEP 6c)
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_DOTNET"; then
  section ".NET 10"
  if ! command -v dotnet &>/dev/null; then
    DOTNET_SCRIPT=$(mktemp /tmp/dotnet-install.XXXXXX.sh)
    if _curl "https://dot.net/v1/dotnet-install.sh" "$DOTNET_SCRIPT" 2>/dev/null; then
      chmod +x "$DOTNET_SCRIPT"
      "$DOTNET_SCRIPT" --channel 10.0 --install-dir "$HOME/.dotnet" 2>/dev/null && \
        log ".NET 10 installed" || warn ".NET install failed"
      rm -f "$DOTNET_SCRIPT"
      export PATH="$HOME/.dotnet:$PATH"
      export DOTNET_ROOT="$HOME/.dotnet"
    else
      warn ".NET download failed — trying apt fallback"
      sudo apt-get install -y -qq dotnet-sdk-10.0 2>/dev/null && log ".NET 10 from apt" || warn ".NET unavailable — install manually from https://dotnet.microsoft.com/"
    fi
  else
    log ".NET $(dotnet --version 2>/dev/null) already installed"
  fi
  _step_done step_dotnet
fi
