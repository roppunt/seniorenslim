#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# build_iso_full.sh
# Integreert B_build_iso.sh en bouwt een BIOS-bootable ISO.
# Vereist:
#   - xorriso, syslinux-common (voor isolinux/vesamenu en opt. isohdpfx.bin)
#   - jouw B_build_iso.sh in dezelfde map als dit script
#   - projectmap bevat ./isolinux/isolinux.bin en ./isolinux/vesamenu.c32
#     (of laat ALLOW_FALLBACK=1 staan zodat B_build_iso ze 1x kan ophalen)
#
# Aanroepen:
#   sudo ./build_iso_full.sh
#
# Variabelen die je kunt aanpassen:
#   STAGING_SRC : bronboom met jouw aangepaste OS-bestanden (wordt gersync'd)
#   WORKDIR     : tijdelijke bouwmap
#   OUTDIR      : outputmap voor de ISO
#   ISO_NAME    : bestandsnaam van de ISO
#   VOLUME_ID   : volume label
# ------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROJECT_DIR_PARENT="$(dirname "$SCRIPT_DIR")"
if [[ -d "$PROJECT_DIR_PARENT/isolinux" ]]; then
  PROJECT_DIR_DEFAULT="$PROJECT_DIR_PARENT"
else
  PROJECT_DIR_DEFAULT="$SCRIPT_DIR"
fi
PROJECT_DIR="${PROJECT_DIR:-$PROJECT_DIR_DEFAULT}"

# === Jij past vooral deze aan =================================================
STAGING_SRC="${STAGING_SRC:-$PROJECT_DIR/staging_root}"
WORKDIR="${WORKDIR:-/tmp/iso_build}"
OUTDIR="${OUTDIR:-$PROJECT_DIR/out}"
VOLUME_ID="${VOLUME_ID:-SENIORENSLIM}"
DATE_TAG="$(date +%Y%m%d)"
ISO_NAME="${ISO_NAME:-SeniorenSlim-${DATE_TAG}.iso}"
# ============================================================================

# Tools checken
if ! command -v xorriso >/dev/null 2>&1; then
  echo "[ERROR] xorriso ontbreekt (installeer met apt install xorriso)" >&2
  exit 1
fi

# Voorbeeld autodetect (optioneel) voor isohybrid MBR-prefix
set +e
ISOHDPFX_BIN="$(dpkg -L syslinux-common 2>/dev/null | grep -E '/isohdpfx\.bin$' | head -n1)"
set -e
if [[ -z "${ISOHDPFX_BIN:-}" ]]; then
  [[ -f /usr/lib/ISOLINUX/isohdpfx.bin ]] && ISOHDPFX_BIN=/usr/lib/ISOLINUX/isohdpfx.bin
  [[ -f /usr/lib/syslinux/isohdpfx.bin  ]] && ISOHDPFX_BIN=/usr/lib/syslinux/isohdpfx.bin
fi

# Mappen aanmaken
mkdir -p "$WORKDIR" "$OUTDIR"

# Stap 1: Staging tree kopiëren
echo "[INFO] Stap 1/4: Staging tree kopiëren → $WORKDIR"
rsync -a --delete "$STAGING_SRC"/ "$WORKDIR"/

# Stap 2: isolinux-bestanden plaatsen via B_build_iso.sh
echo "[INFO] Stap 2/4: isolinux-bestanden plaatsen via B_build_iso.sh"
chmod +x "$SCRIPT_DIR/B_build_iso.sh"
"$SCRIPT_DIR/B_build_iso.sh" "$WORKDIR/isolinux"

# Verplicht voor isolinux boot
BOOT_BIN="isolinux/isolinux.bin"
BOOT_CAT="isolinux/boot.cat"

# Stap 3: ISO bouwen met xorriso
echo "[INFO] Stap 3/4: ISO bouwen met xorriso"
ISO_PATH="$OUTDIR/$ISO_NAME"

# Basis mkisofs-args voor BIOS/isolinux boot
declare -a MKISOFS_ARGS=(
  -o "$ISO_PATH"
  -V "$VOLUME_ID"
  -J -r -iso-level 3
  -b "$BOOT_BIN"
  -c "$BOOT_CAT"
  -no-emul-boot
  -boot-load-size 4
  -boot-info-table
)

# Optioneel: hybride MBR zodat de ISO ook direct USB-bootable is
if [[ -n "${ISOHDPFX_BIN:-}" && -f "$ISOHDPFX_BIN" ]]; then
  echo "[INFO] isohybrid MBR gevonden: $ISOHDPFX_BIN (hybride ISO/USB boot ingeschakeld)"
  MKISOFS_ARGS+=( -isohybrid-mbr "$ISOHDPFX_BIN" )
else
  echo "[WARN] isohdpfx.bin niet gevonden; ISO is nog steeds BIOS-bootable, maar mogelijk niet direct 'hybride' voor USB."
fi

# Bouw de ISO
xorriso -as mkisofs "${MKISOFS_ARGS[@]}" "$WORKDIR"

# Stap 4: Klaar
echo "[INFO] Stap 4/4: Klaar."
echo "[OK] ISO gebouwd: $ISO_PATH"
