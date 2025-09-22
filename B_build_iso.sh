#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# B_build_iso.sh
# Gebruik isolinux-bestanden uit je projectmap i.p.v. ensure_isolinux.
#
# Vereist:
#   - In je projectmap bestaat: ./isolinux/isolinux.bin en ./isolinux/vesamenu.c32
#     (Tip: zet ze onder versiebeheer in Git)
#
# Aanroepen (voorbeeld):
#   ./B_build_iso.sh /pad/naar/doel1 /pad/naar/doel2
#
# Omgevingsvariabelen (optioneel):
#   PROJECT_DIR  : root van je project (default = map van dit script)
#   ISO_SRC_DIR  : pad naar map met isolinux-bestanden (default = $PROJECT_DIR/isolinux)
#   ALLOW_FALLBACK=1 om bij ontbreken automatisch te proberen uit systeem te halen
#                   (dpkg -L syslinux-common). Default = 1 (aan).
# ------------------------------------------------------------

# Locaties instellen
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$SCRIPT_DIR}"
ISO_SRC_DIR="${ISO_SRC_DIR:-$PROJECT_DIR/isolinux}"
ALLOW_FALLBACK="${ALLOW_FALLBACK:-1}"

ISO_BIN_SRC="$ISO_SRC_DIR/isolinux.bin"
VESA_MENU_SRC="$ISO_SRC_DIR/vesamenu.c32"

# ---- Hulp: nette foutmelding
die() { echo "[ERROR] $*" >&2; exit 1; }

# ---- Probeer ontbrekende bestanden 1x automatisch te vullen vanaf het systeem
maybe_populate_from_system() {
  # Alleen als toegestaan en één van beide ontbreekt
  if [[ "$ALLOW_FALLBACK" != "1" ]]; then return 0; fi
  if [[ -f "$ISO_BIN_SRC" && -f "$VESA_MENU_SRC" ]]; then return 0; fi

  echo "[INFO] Probeer isolinux-bestanden vanuit het systeem te vinden (syslinux-common)…"

  set +e
  ISO_BIN_SYS="$(dpkg -L syslinux-common 2>/dev/null | grep -E '/(ISOLINUX|syslinux)/isolinux\.bin$' | head -n1)"
  VESA_MENU_SYS="$(dpkg -L syslinux-common 2>/dev/null | grep -E '/vesamenu\.c32$' | head -n1)"
  set -e

  # Extra fallbacks (sommige distro's)
  [[ -z "${ISO_BIN_SYS:-}" && -f /usr/lib/ISOLINUX/isolinux.bin ]] && ISO_BIN_SYS=/usr/lib/ISOLINUX/isolinux.bin
  [[ -z "${ISO_BIN_SYS:-}" && -f /usr/lib/syslinux/isolinux.bin ]]  && ISO_BIN_SYS=/usr/lib/syslinux/isolinux.bin
  [[ -z "${VESA_MENU_SYS:-}" && -f /usr/lib/syslinux/modules/bios/vesamenu.c32 ]] && VESA_MENU_SYS=/usr/lib/syslinux/modules/bios/vesamenu.c32

  mkdir -p "$ISO_SRC_DIR"

  if [[ -n "${ISO_BIN_SYS:-}" && -f "$ISO_BIN_SYS" ]]; then
    echo "[INFO] Kopieer $ISO_BIN_SYS → $ISO_BIN_SRC"
    cp -f "$ISO_BIN_SYS" "$ISO_BIN_SRC"
  fi
  if [[ -n "${VESA_MENU_SYS:-}" && -f "$VESA_MENU_SYS" ]]; then
    echo "[INFO] Kopieer $VESA_MENU_SYS → $VESA_MENU_SRC"
    cp -f "$VESA_MENU_SYS" "$VESA_MENU_SRC"
  fi
}

# ---- Validatie bronbestanden
validate_sources() {
  [[ -f "$ISO_BIN_SRC" ]] || die "Bestand ontbreekt: $ISO_BIN_SRC\nHint: plaats 'isolinux.bin' in $ISO_SRC_DIR (of zet ALLOW_FALLBACK=1)."
  [[ -f "$VESA_MENU_SRC" ]] || die "Bestand ontbreekt: $VESA_MENU_SRC\nHint: plaats 'vesamenu.c32' in $ISO_SRC_DIR (of zet ALLOW_FALLBACK=1)."
}

# ---- Kopieer naar een doelmap
copy_to_target() {
  local target="$1"
  [[ -d "$target" ]] || mkdir -p "$target"

  echo "[INFO] Kopieer isolinux → $target"
  install -m 0644 "$ISO_BIN_SRC"   "$target/isolinux.bin"
  install -m 0644 "$VESA_MENU_SRC" "$target/vesamenu.c32"
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
if [[ "$#" -lt 1 ]]; then
  cat >&2 <<'USAGE'
Gebruik:
  ./B_build_iso.sh <DOELMAP> [<DOELMAP2> <DOELMAP3> ...]

Voorbeeld:
  sudo ./B_build_iso.sh /root/iso_staging/isolinux

Opties via env:
  PROJECT_DIR=/pad/naar/project
  ISO_SRC_DIR=/pad/naar/project/isolinux
  ALLOW_FALLBACK=0   # fallback uitschakelen
USAGE
  exit 2
fi

maybe_populate_from_system
validate_sources

for dest in "$@"; do
  copy_to_target "$dest"
done

echo "[OK] isolinux-bestanden gekopieerd vanuit: $ISO_SRC_DIR"
