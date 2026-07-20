#!/usr/bin/env python3
"""Daemon launcher for kimi-anthropic-proxy (v5 - reasoning stripper)."""
import os
import sys

PROXY = "/home/alexandr-narbaev/Projects/opencode_initializer/scripts/kimi-anthropic-proxy.py"
LOG = "/home/alexandr-narbaev/Projects/opencode_initializer/.kimi-proxy-v5.log"
SECRETS = "/home/alexandr-narbaev/.config/opencode/secrets.env"

pid = os.fork()
if pid > 0:
    print(f"Started daemon PID={pid}")
    sys.exit(0)

os.setsid()
pid = os.fork()
if pid > 0:
    sys.exit(0)

# Load secrets.env
if os.path.exists(SECRETS):
    with open(SECRETS) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            k, _, v = line.partition('=')
            v = v.strip().strip('"').strip("'")
            os.environ[k] = v

sys.stdin = open("/dev/null", "r")
log = open(LOG, "a")
os.dup2(log.fileno(), 1)
os.dup2(log.fileno(), 2)
os.execv(sys.executable, [sys.executable, PROXY])
