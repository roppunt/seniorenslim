#!/usr/bin/env bash
set -euo pipefail

# Vereist: docker
if ! command -v docker >/dev/null; then
  echo "Docker vereist"; exit 1
fi

# Build container met live-build tooling
docker run --rm -it -v "$(pwd)":/ws debian:12 bash -lc '
apt-get update && apt-get install -y live-build syslinux-common xorriso wget git ca-certificates
cd /ws
rm -rf live-build && mkdir live-build && cd live-build

# Config
lb config \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --debian-installer live \
  --distribution bookworm \
  --apt-indices false \
  --bootappend-live "boot=live components quiet splash locales=nl_NL.UTF-8"

# Paketten (XFCE, chromium, thunderbird, rustdesk, shotwell, vlc)
mkdir -p config/package-lists
cat > config/package-lists/seniorenslim.list.chroot <<PKG
xfce4 xfce4-goodies lightdm lightdm-gtk-greeter plymouth plymouth-themes
chromium firefox-esr thunderbird vlc shotwell ufw curl unzip jq
rustdesk fonts-dejavu-core
PKG

# Branding: skel en thema's
mkdir -p config/includes.chroot/etc/skel
cp -a /ws/config/desktop/skeleton/* config/includes.chroot/etc/skel/ || true

# Plymouth/GRUB/LightDM thema's
mkdir -p config/includes.chroot/usr/share/seniorenslim
cp -a /ws/assets/branding/* config/includes.chroot/usr/share/seniorenslim/ || true

# Post-install hooks (chroot)
mkdir -p config/hooks
cp -a /ws/scripts/B_postinstall_hooks.sh config/hooks/010-seniorenslim.chroot

# Build
lb build
mv *.iso /ws/iso/seniorenslim-$(date +%Y%m%d).iso
'
echo "ISO klaar in ./iso/"
