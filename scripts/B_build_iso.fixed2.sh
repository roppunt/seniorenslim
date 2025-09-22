#!/usr/bin/env bash
set -euo pipefail

# Wrapper script for GitHub Actions to build SeniorenSlim ISO using build_iso_full.sh.
# This script calls build_iso_full.sh with the appropriate environment variables.

echo "[INFO] Starting build_iso_full.sh from B_build_iso.fixed2.sh"

# Ensure the build_iso_full.sh script is executable
chmod +x build_iso_full.sh

# Set staging source to 'iso' and output directory to 'dist' for GitHub Actions
STAGING_SRC=iso OUTDIR=dist bash build_iso_full.sh
