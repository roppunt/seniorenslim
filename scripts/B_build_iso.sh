#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="${REPO_ROOT}/dist"
ISO_DIR="${REPO_ROOT}/iso"

mkdir -p "${DIST_DIR}"
cd "${ISO_DIR}"

sudo lb clean || true

# Live-build configuratie (zonder verouderde flags)
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
  --security false

# Provide custom apt sources to avoid invalid bookworm/updates entries
sudo mkdir -p config/apt
cat > config/apt/sources.list <<'EOF'
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF
sudo cp config/apt/sources.list config/apt/sources.list.chroot

# Build
sudo lb build

# Resultaat verplaatsen
ISO_FILE="$(ls -1 *.iso 2>/dev/null | head -n1 || true)"
if [[ -z "${ISO_FILE}" ]]; then
  echo "ERROR: no ISO produced"
  exit 1
fi
mv -f "${ISO_FILE}" "${DIST_DIR}/seniorenslim-bookworm-amd64.iso"
echo "ISO saved to ${DIST_DIR}/seniorenslim-bookworm-amd64.iso"
