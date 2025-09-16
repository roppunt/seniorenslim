#!/usr/bin/env bash
set -euo pipefail
URL="https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-1.3.6-x86_64.deb"
TMP="/tmp/rustdesk.deb"
curl -fsSL "$URL" -o "$TMP"
apt install -y "$TMP" || dpkg -i "$TMP"
systemctl enable --now rustdesk || true
