#!/usr/bin/env bash
set -e

# Schoon oude build op
lb clean

# Configureer live-build
lb config \
  --mode debian \
  --distribution bookworm \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --debian-installer live \
  --apt-recommends true \
  --security true \
  --archive-areas "main contrib non-free non-free-firmware" \
  --mirror-bootstrap http://deb.debian.org/debian/ \
  --mirror-binary http://deb.debian.org/debian/ \
  --mirror-binary-security http://deb.debian.org/debian-security/

# Build de ISO
lb build
