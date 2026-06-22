#!/usr/bin/env bash
# fix-sublime-apt-key.sh — Fix Sublime Text GPG key for apt
# Run: sudo bash scripts/fix-sublime-apt-key.sh
set -euo pipefail

echo "[*] Fixing Sublime Text GPG key..."
curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/sublimehq-archive.gpg > /dev/null
sudo chmod 644 /usr/share/keyrings/sublimehq-archive.gpg
echo "[✓] Key fixed. Run: sudo apt update"
