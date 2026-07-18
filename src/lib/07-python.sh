#!/usr/bin/env bash
# lib/07-python.sh — Python 3.14.6 + uv (STEP 6)
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_PYTHON"; then
  section "Python 3.14.6 + uv"
  if ! command -v uv &>/dev/null; then
    UV_SCRIPT=$(mktemp /tmp/uv-install.XXXXXX.sh)
    if _curl "https://astral.sh/uv/install.sh" "$UV_SCRIPT" 2>/dev/null; then
      sh "$UV_SCRIPT" && log "uv installed" || warn "uv install script failed"
      rm -f "$UV_SCRIPT"
      export PATH="$HOME/.cargo/bin:$PATH"
    else
      warn "uv download failed — using pip from apt"
    fi
  else
    log "uv already installed"
  fi
  command -v uv &>/dev/null && uv python install 3.14 --default 2>/dev/null || true
  if ! curl -fsSL --connect-timeout 5 https://pypi.org -o /dev/null 2>/dev/null; then
    pip3 config set global.index-url "$PYPI_MIRROR" 2>/dev/null || true
    command -v uv &>/dev/null && mkdir -p "$HOME/.config/uv" && echo "index-url = $PYPI_MIRROR" > "$HOME/.config/uv/uv.toml" 2>/dev/null || true
  fi
  command -v uv &>/dev/null && uv pip install --user --upgrade pip 2>/dev/null || true
  PYTHON_BIN="$( (command -v uv &>/dev/null && uv python find 3.14 2>/dev/null) || which python3.14 2>/dev/null || which python3 2>/dev/null || true)"
  [ -n "$PYTHON_BIN" ] && sudo update-alternatives --install /usr/bin/python python "$PYTHON_BIN" 1 2>/dev/null || true
  log "Python 3.14.6 OK"
  _step_done step_python
fi
