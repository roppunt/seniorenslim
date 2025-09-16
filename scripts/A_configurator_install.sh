#!/usr/bin/env bash
set -euo pipefail

# === SeniorenSlim Configurator v1.0 ===
# Doel: van een schone Zorin/Debian XFCE/MATE installatie -> SeniorenSlim desktop in 5 min.

log() { echo "[SeniorenSlim] $*"; }

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Voer dit script uit met sudo of als root."
    exit 1
  fi
}

detect_pkg() {
  if command -v apt >/dev/null 2>&1; then
    PKG=apt
  else
    echo "Alleen apt-gebaseerde distro's worden nu ondersteund."
    exit 1
  fi
}

update_system() {
  $PKG update -y || true
}

install_pkgs() {
  $PKG install -y --no-install-recommends \
    chromium-browser firefox-esr thunderbird \
    vlc shotwell xfce4-whiskermenu-plugin \
    rustdesk ufw curl unzip jq fonts-dejavu-core
}

# Desktop branding en defaults
apply_branding() {
  # Achtergrond en iconen
  mkdir -p /usr/share/seniorenslim/{wallpapers,icons}
  cp -a /tmp/seniorenslim/assets/branding/wallpaper.jpg /usr/share/seniorenslim/wallpapers/wallpaper.jpg || true
  cp -a /tmp/seniorenslim/assets/branding/iconset/* /usr/share/seniorenslim/icons/ || true

  # Achtergrond instellen voor alle nieuwe users (XFCE voorbeeld)
  mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
  cat >/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/usr/share/seniorenslim/wallpapers/wallpaper.jpg"/>
        </property>
      </property>
    </property>
  </property>
</channel>
XML

  # Welkomvenster (autostart) voor nieuwe users
  mkdir -p /etc/skel/.config/autostart
  cat >/etc/skel/.config/autostart/seniorenslim-welcome.desktop <<'DESK'
[Desktop Entry]
Type=Application
Name=Welkom bij SeniorenSlim
Exec=xdg-open /usr/share/seniorenslim/docs/quickstart.pdf
X-GNOME-Autostart-enabled=true
DESK

  # Handleidingen
  mkdir -p /usr/share/seniorenslim/docs
  cp -a /tmp/seniorenslim/assets/docs/* /usr/share/seniorenslim/docs/ || true
}

# Bureaublad snelkoppelingen + banklinks
apply_shortcuts() {
  mkdir -p /etc/skel/Desktop
  chmod 755 /etc/skel/Desktop

  mkdesk() {
    local name="$1" exec="$2" icon="$3"
    cat >/etc/skel/Desktop/${name}.desktop <<DESK
[Desktop Entry]
Type=Application
Name=${name}
Exec=${exec}
Icon=${icon}
Terminal=false
Categories=Utility;
X-GNOME-Autostart-enabled=false
DESK
    chmod +x /etc/skel/Desktop/${name}.desktop
  }

  mkdesk "Internet" "chromium-browser" "/usr/share/seniorenslim/icons/internet.png"
  mkdesk "E-mail" "chromium-browser https://outlook.com" "/usr/share/seniorenslim/icons/email.png"
  mkdesk "Videobellen" "chromium-browser https://web.whatsapp.com" "/usr/share/seniorenslim/icons/video.png"
  mkdesk "Foto's" "shotwell" "/usr/share/seniorenslim/icons/photos.png"
  mkdesk "Bankieren" "chromium-browser https://www.ing.nl" "/usr/share/seniorenslim/icons/bank.png"
}

# Policies (Chrome/Firefox) – popups rustig, updates aan, beveiliging strak
browser_policies() {
  # Chromium
  mkdir -p /etc/chromium/policies/managed
  cat >/etc/chromium/policies/managed/seniorenslim.json <<'JSON'
{
  "HomepageLocation": "https://start.seniorenslim.nl",
  "RestoreOnStartup": 4,
  "RestoreOnStartupURLs": ["https://start.seniorenslim.nl"],
  "PasswordManagerEnabled": true,
  "DefaultPopupsSetting": 2,
  "AutofillAddressEnabled": false,
  "AutofillCreditCardEnabled": false
}
JSON

  # Firefox (policies.json)
  mkdir -p /usr/lib/firefox/distribution
  cat >/usr/lib/firefox/distribution/policies.json <<'JSON'
{
  "policies": {
    "Homepage": {
      "URL": "https://start.seniorenslim.nl",
      "Locked": false,
      "StartPage": "homepage"
    },
    "DisableFirefoxStudies": true,
    "DisablePocket": true,
    "OfferToSaveLogins": true
  }
}
JSON
}

# Stille updates + vriendelijke melding
install_update_buddy() {
  install -m 755 /tmp/seniorenslim/scripts/A_update_buddy.sh /usr/local/bin/update-buddy
  # Cron (dagelijks 10:00)
  (crontab -l 2>/dev/null; echo "0 10 * * * /usr/local/bin/update-buddy >/var/log/update-buddy.log 2>&1") | crontab -
}

# Rustdesk remote support
install_rustdesk() {
  bash /tmp/seniorenslim/scripts/A_rustdesk_install.sh || true
}

# Firewall basic
secure_defaults() {
  ufw default deny incoming || true
  ufw default allow outgoing || true
  ufw allow 21115/tcp || true  # Rustdesk rendezvous (optioneel)
  ufw --force enable || true
}

main() {
  require_root
  detect_pkg
  update_system
  install_pkgs
  apply_branding
  apply_shortcuts
  browser_policies
  install_update_buddy
  install_rustdesk
  secure_defaults
  log "Klaar. Nieuwe gebruikers krijgen automatisch de SeniorenSlim-omgeving."
  log "Tip: maak nu een nieuw account voor de eindgebruiker."
}

# Fetch repo tarball naar /tmp/seniorenslim indien direct via curl gebruikt
if [ ! -d /tmp/seniorenslim ]; then
  mkdir -p /tmp/seniorenslim
  curl -fsSL https://codeload.github.com/<jouw-org>/seniorenslim/zip/refs/heads/main -o /tmp/seniorenslim.zip
  unzip -q /tmp/seniorenslim.zip -d /tmp/
  mv /tmp/seniorenslim-main /tmp/seniorenslim
fi

main
