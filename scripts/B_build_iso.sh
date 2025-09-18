#!/usr/bin/env bash
set -euo pipefail

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

sudo mkdir -p config/apt/apt.conf.d
cat > config/apt/apt.conf.d/no-content.conf <<'EOF'
Acquire::Languages "none";
Acquire::IndexTargets::deb::Contents "false";
EOF
sudo cp -r config/apt/apt.conf.d config/apt/apt.conf.d.chroot


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
