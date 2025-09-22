#!/bin/bash
set -e

# Plymouth theme registreren
if [ -d /usr/share/seniorenslim/plymouth ]; then
  THEME_DIR="/usr/share/seniorenslim/plymouth"
  ln -sf "$THEME_DIR/seniorenslim.plymouth" /usr/share/plymouth/themes/seniorenslim.plymouth
  /usr/sbin/plymouth-set-default-theme -R seniorenslim || true
fi

# LightDM greeter
if [ -f /usr/share/seniorenslim/greeter/lightdm-gtk-greeter.conf ]; then
  install -d /etc/lightdm
  cp /usr/share/seniorenslim/greeter/lightdm-gtk-greeter.conf /etc/lightdm/
fi

# GRUB achtergrond
if [ -f /usr/share/seniorenslim/grub/background.png ]; then
  mkdir -p /boot/grub
  cp /usr/share/seniorenslim/grub/background.png /boot/grub/
  sed -i "s|^#*GRUB_BACKGROUND=.*|GRUB_BACKGROUND=/boot/grub/background.png|" /etc/default/grub || true
  update-grub || true
fi

# Desktop policies browsers
mkdir -p /etc/chromium/policies/managed
cat >/etc/chromium/policies/managed/seniorenslim.json <<'JSON'
{"HomepageLocation":"https://start.seniorenslim.nl","RestoreOnStartup":4,"RestoreOnStartupURLs":["https://start.seniorenslim.nl"]}
JSON

mkdir -p /usr/lib/firefox/distribution
cat >/usr/lib/firefox/distribution/policies.json <<'JSON'
{"policies":{"Homepage":{"URL":"https://start.seniorenslim.nl","StartPage":"homepage"}}}
JSON

# UFW basis
ufw default deny incoming || true
ufw default allow outgoing || true
ufw allow 21115/tcp || true
yes | ufw enable || true

# Update-buddy
cat <<'SH' >/usr/local/bin/update-buddy
#!/usr/bin/env bash
set -euo pipefail
if ! command -v apt >/dev/null 2>&1; then exit 0; fi
export DEBIAN_FRONTEND=noninteractive
apt update -y || true
apt dist-upgrade -y || true
apt autoremove -y || true
notify-send "SeniorenSlim" "Je computer is bijgewerkt en weer veilig. 👍" || true
SH
chmod 755 /usr/local/bin/update-buddy
(crontab -l 2>/dev/null; echo "0 10 * * * /usr/local/bin/update-buddy >/var/log/update-buddy.log 2>&1") | crontab - || true
