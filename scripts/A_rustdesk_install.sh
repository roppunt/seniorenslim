#!/usr/bin/env bash
set -euo pipefail
[ "${EUID:-$(id -u)}" -eq 0 ] || { echo "Run as root (sudo)"; exit 1; }

apt-get update -y
apt-get install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.rustdesk.RustDesk
echo "RustDesk geïnstalleerd via Flatpak ✅"
