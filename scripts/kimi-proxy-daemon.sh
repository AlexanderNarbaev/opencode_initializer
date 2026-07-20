#!/usr/bin/env bash
# Daemon launcher for kimi proxy
cd /home/alexandr-narbaev/Projects/opencode_initializer || exit 1
exec setsid python3 scripts/kimi-anthropic-proxy.py < /dev/null