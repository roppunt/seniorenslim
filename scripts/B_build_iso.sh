#!/usr/bin/env bash
set -euo pipefail

# --- Zorg dat isolinux/syslinux bestanden bestaan voor BIOS boot (Debian 12+) ---
# Boekworm gebruikt meestal:
#   /usr/lib/ISOLINUX/isolinux.bin
#   /usr/lib/syslinux/modules/bios/vesamenu.c32

set +e
ISO_BIN="$(dpkg -L syslinux-common 2>/dev/null | grep -E '/(ISOLINUX|syslinux)/isolinux\.bin$' | head -n1)"
VESA_MENU="$(dpkg -L syslinux-common 2>/dev/null | grep -E '/vesamenu\.c32$' | head -n1)"
set -e

# Fallbacks
[ -z "$ISO_BIN" ]   && [ -f /usr/lib/ISOLINUX/isolinux.bin ] && ISO_BIN=/usr/lib/ISOLINUX/isolinux.bin
[ -z "$ISO_BIN" ]   && [ -f /usr/lib/syslinux/isolinux.bin ] && ISO_BIN=/usr/lib/syslinux/isolinux.bin
[ -z "$VESA_MENU" ] && [ -f /usr/lib/syslinux/modules/bios/vesamenu.c32 ] && VESA_MENU=/usr/lib/syslinux/modules/bios/vesamenu.c32
[ -z "$VESA_MENU" ] && [ -f /usr/lib/syslinux/vesamenu.c32 ] && VESA_MENU=/usr/lib/syslinux/vesamenu.c32

sudo mkdir -p /root/isolinux
if [ -n "$ISO_BIN" ] && [ -f "$ISO_BIN" ]; then
  sudo install -m 0644 "$ISO_BIN" /root/isolinux/isolinux.bin
else
  echo "Waarschuwing: isolinux.bin niet gevonden (syslinux-common niet volledig?); build kan later falen." >&2
fi
if [ -n "$VESA_MENU" ] && [ -f "$VESA_MENU" ]; then
  sudo install -m 0644 "$VESA_MENU" /root/isolinux/vesamenu.c32
else
  echo "Waarschuwing: vesamenu.c32 niet gevonden; build kan later falen." >&2
fi
# --- einde isolinux fix ---

# Padstructuren bepalen
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="${REPO_ROOT}/dist"
ISO_DIR="${REPO_ROOT}/iso"

# Output directories
mkdir -p "${DIST_DIR}"
cd "${ISO_DIR}"

# APT configuratie
sudo mkdir -p config/apt
cat > config/apt/sources.list <<'EOF'
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security bookworm-security main
EOF
sudo cp config/apt/sources.list config/apt/sources.list.chroot

sudo mkdir -p config/apt/apt.conf.d
cat > config/apt/apt.conf.d/no-content.conf <<'EOF'
Acquire::Languages "none";
Acquire::IndexTargets::deb::Contents "false";
EOF
sudo cp -r config/apt/apt.conf.d config/apt/apt.conf.d.chroot

# Hooks uitvoerbaar maken
if [ -d "iso/config/hooks/normal" ]; then
  chmod +x iso/config/hooks/normal/*.hook.* 2>/dev/null || true
fi

# Vorige build opschonen
sudo lb clean || true

# Live-build configuratie
sudo lb config \
  --mode debian \
  --distribution bookworm \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --debian-installer false \
  --apt-recommends true \
  --archive-areas "main contrib non-free non-free-firmware" \
  --mirror-bootstrap http://deb.debian.org/debian \
  --mirror-chroot   http://deb.debian.org/debian \
  --mirror-binary   http://deb.debian.org/debian \
  --security false \
  --linux-packages none \
  --firmware-binary false \
  --firmware-chroot false \
  --memtest none

# ISO bouwen
sudo lb build

# ISO verplaatsen
ISO_FILE="$(ls -1 *.iso 2>/dev/null | head -n1 || true)"
if [[ -z "${ISO_FILE}" ]]; then
  echo "ERROR: geen ISO aangemaakt"
  exit 1
fi
mv -f "${ISO_FILE}" "${DIST_DIR}/seniorenslim-bookworm-amd64.iso"
echo "ISO opgeslagen als ${DIST_DIR}/seniorenslim-bookworm-amd64.iso"
