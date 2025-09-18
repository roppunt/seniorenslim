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

# Clean previous build if any (ignore errors)
sudo lb clean || true

# Run live-build configuration with updated options
sudo lb config \
  --mode debian \
  --distribution bookworm \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --debian-installer live \
  --apt-recommends true \
  --archive-areas "main contrib non-free non-free-firmware" \
  --mirror-bootstrap http://deb.debian.org/debian \
  --mirror-binary http://deb.debian.org/debian \
  --mirror-chroot-security http://deb.debian.org/debian-security \
  --mirror-binary-security http://deb.debian.org/debian-security \
  --security false \
  --linux-packages none

# Provide custom apt sources to avoid invalid bookworm/updates entries
sudo mkdir -p config/apt
cat > config/apt/sources.list <<'APT_EOF'
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
APT_EOF
sudo cp config/apt/sources.list config/apt/sources.list.chroot

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
