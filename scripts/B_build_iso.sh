#!/usr/bin/env bash
set -euo pipefail
# --- fix: ensure isolinux/syslinux files exist for BIOS boot (Debian 12+) ---
# Find actual paths provided by syslinux-common; Bookworm typically uses:
#   /usr/lib/ISOLINUX/isolinux.bin
#   /usr/lib/syslinux/modules/bios/vesamenu.c32
set +e
ISO_BIN="$(dpkg -L syslinux-common 2>/dev/null | grep -E '/(ISOLINUX|syslinux)/isolinux\.bin$' | head -n1)"
VESA_MENU="$(dpkg -L syslinux-common 2>/dev/null | grep -E '/vesamenu\.c32$' | head -n1)"
set -e
# Fallbacks
[ -z "$ISO_BIN" ] && [ -f /usr/lib/ISOLINUX/isolinux.bin ] && ISO_BIN=/usr/lib/ISOLINUX/isolinux.bin
[ -z "$ISO_BIN" ] && [ -f /usr/lib/syslinux/isolinux.bin ] && ISO_BIN=/usr/lib/syslinux/isolinux.bin
[ -z "$VESA_MENU" ] && [ -f /usr/lib/syslinux/modules/bios/vesamenu.c32 ] && VESA_MENU=/usr/lib/syslinux/modules/bios/vesamenu.c32
[ -z "$VESA_MENU" ] && [ -f /usr/lib/syslinux/vesamenu.c32 ] && VESA_MENU=/usr/lib/syslinux/vesamenu.c32

# --- ensure isolinux files exist on Bookworm ---
set +e
ISO_BIN="$(dpkg -L syslinux-common 2>/dev/null | grep -E '/(ISOLINUX|syslinux)/isolinux\.bin$' | head -n1)"
VESA_MENU="$(dpkg -L syslinux-common 2>/dev/null | grep -E '/vesamenu\.c32$' | head -n1)"
set -e
[ -z "$ISO_BIN" ]   && [ -f /usr/lib/ISOLINUX/isolinux.bin ] && ISO_BIN=/usr/lib/ISOLINUX/isolinux.bin
[ -z "$ISO_BIN" ]   && [ -f /usr/lib/syslinux/isolinux.bin ] && ISO_BIN=/usr/lib/syslinux/isolinux.bin
[ -z "$VESA_MENU" ] && [ -f /usr/lib/syslinux/modules/bios/vesamenu.c32 ] && VESA_MENU=/usr/lib/syslinux/modules/bios/vesamenu.c32
[ -z "$VESA_MENU" ] && [ -f /usr/lib/syslinux/vesamenu.c32 ] && VESA_MENU=/usr/lib/syslinux/vesamenu.c32

sudo mkdir -p /root/isolinux
if [ -n "$ISO_BIN" ] && [ -f "$ISO_BIN" ]; then
  sudo install -m 0644 "$ISO_BIN" /root/isolinux/isolinux.bin
fi
if [ -n "$VESA_MENU" ] && [ -f "$VESA_MENU" ]; then
  sudo install -m 0644 "$VESA_MENU" /root/isolinux/vesamenu.c32
fi
# --- end ensure block ---


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
# --- end fix ---

# Determine script and repository directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="${REPO_ROOT}/dist"
ISO_DIR="${REPO_ROOT}/iso"

# Ensure output directories exist
mkdir -p "${DIST_DIR}"
cd "${ISO_DIR}"

sudo mkdir -p config/apt
cat > config/apt/sources.list <<'EOF'
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security bookworm-security main
EOF
sudo cp config/apt/sources.list config/apt/sources.list.chroot

# Maak /root/isolinux aan en kopieer isolinux-bestanden
sudo mkdir -p /root/isolinux
# isolinux.bin bevindt zich in /usr/lib/ISOLINUX/
if [ -f /usr/lib/ISOLINUX/isolinux.bin ]; then
  sudo cp /usr/lib/ISOLINUX/isolinux.bin /root/isolinux/isolinux.bin
fi
# vesamenu.c32 bevindt zich in /usr/lib/syslinux/modules/bios/
if [ -f /usr/lib/syslinux/modules/bios/vesamenu.c32 ]; then
  sudo cp /usr/lib/syslinux/modules/bios/vesamenu.c32 /root/isolinux/vesamenu.c32
fi


sudo mkdir -p config/apt/apt.conf.d
cat > config/apt/apt.conf.d/no-content.conf <<'EOF'
Acquire::Languages "none";
Acquire::IndexTargets::deb::Contents "false";
EOF
sudo cp -r config/apt/apt.conf.d config/apt/apt.conf.d.chroot

# Zorg dat hooks uitvoerbaar zijn, ook als GitHub UI exec bit verliest
if [ -d "iso/config/hooks/normal" ]; then
  chmod +x iso/config/hooks/normal/*.hook.* 2>/dev/null || true
fi


# Clean previous build if any (ignore errors)
sudo lb clean || true

# Run live-build configuration with updated options
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
  --firmware-chroot false

# Provide custom apt sources to avoid invalid bookworm/updates entries
sudo mkdir -p config/apt
cat > config/apt/sources.list <<'APT_EOF'
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security bookworm-security main
APT_EOF
sudo cp config/apt/sources.list config/apt/sources.list.chroot

sudo mkdir -p config/apt/apt.conf.d
cat > config/apt/apt.conf.d/no-content.conf <<'CONF_EOF'
Acquire::Languages "none";
Acquire::IndexTargets::deb::Contents "false";
CONF_EOF
sudo cp -r config/apt/apt.conf.d config/apt/apt.conf.d.chroot

# Maak /root/isolinux aan en kopieer isolinux-bestanden
sudo mkdir -p /root/isolinux
# isolinux.bin bevindt zich in /usr/lib/ISOLINUX/
if [ -f /usr/lib/ISOLINUX/isolinux.bin ]; then
  sudo cp /usr/lib/ISOLINUX/isolinux.bin /root/isolinux/isolinux.bin
fi
# vesamenu.c32 bevindt zich in /usr/lib/syslinux/modules/bios/
if [ -f /usr/lib/syslinux/modules/bios/vesamenu.c32 ]; then
  sudo cp /usr/lib/syslinux/modules/bios/vesamenu.c32 /root/isolinux/vesamenu.c32
fi


# Build the ISO image
sudo lb build

# Move the resulting ISO to the dist directory with a fixed name
ISO_FILE="$(ls -1 *.iso 2>/dev/null | head -n1 || true)"
if [[ -z "${ISO_FILE}" ]]; then
  echo "ERROR: no ISO produced"
  exit 1
fi
mv -f "${ISO_FILE}" "${DIST_DIR}/seniorenslim-bookworm-amd64.iso"
echo "ISO saved to ${DIST_DIR}/seniorenslim-bookworm-amd64.iso"
