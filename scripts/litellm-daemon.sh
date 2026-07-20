#!/usr/bin/env bash
# Daemon launcher for litellm proxy
cd /home/alexandr-narbaev/Projects/opencode_initializer || exit 1
exec setsid /home/alexandr-narbaev/.local/share/pipx/venvs/litellm/bin/litellm \
  --config litellm-config.yaml --port 9876 < /dev/null