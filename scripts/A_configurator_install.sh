#!/usr/bin/env bash
set -euo pipefail

REPO="roppunt/seniorenslim"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

need_root() { [ "${EUID:-$(id -u)}" -eq 0 ] || { echo "Run as root (sudo)"; exit 1; }; }
need_root

echo "[1/8] Packages installeren…"
export DEBIAN_FRONTEND=noninteractive

OS_ID="onbekend"
OS_ID_LIKE=""
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  OS_ID="${ID:-onbekend}"
  OS_ID_LIKE="${ID_LIKE:-}"
fi

FIREFOX_PACKAGE="firefox"
case "${OS_ID}" in
  debian)
    FIREFOX_PACKAGE="firefox-esr"
    ;;
esac

echo "Distributie gedetecteerd: ${OS_ID} (${OS_ID_LIKE:-geen ID_LIKE}); gebruik ${FIREFOX_PACKAGE}."

apt-get update -y
apt-get install -y --no-install-recommends \
  chromium \
  "${FIREFOX_PACKAGE}" \
  ufw \
  unattended-upgrades \
  curl \
  jq \
  xdg-utils \
  libnotify-bin \
  ca-certificates \
  locales \
  shotwell \
  flatpak

echo "[2/8] Chromium wrapper/symlink…"
CMD="$(command -v chromium || true)"
[ -z "$CMD" ] && CMD="$(command -v chromium-browser || true)"
if [ -n "$CMD" ]; then
  ln -sf "$CMD" /usr/local/bin/chromium-browser
fi

echo "[3/8] Locale NL als standaard…"
sed -i 's/^# *nl_NL.UTF-8/nl_NL.UTF-8/' /etc/locale.gen || true
locale-gen nl_NL.UTF-8
update-locale LANG=nl_NL.UTF-8

echo "[4/8] Firewall + automatische updates…"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH || true
ufw --force enable
cat >/etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

echo "[5/8] Branding kopiëren…"
install -d /usr/share/seniorenslim/icons /usr/share/seniorenslim/docs
curl -fsSL "${RAW}/assets/branding/logo.png"       -o /usr/share/seniorenslim/logo.png
curl -fsSL "${RAW}/assets/branding/wallpaper.jpg"  -o /usr/share/seniorenslim/wallpaper.jpg
curl -fsSL "${RAW}/assets/branding/icons/internet.png" -o /usr/share/seniorenslim/icons/internet.png
curl -fsSL "${RAW}/assets/branding/icons/email.png"    -o /usr/share/seniorenslim/icons/email.png
curl -fsSL "${RAW}/assets/branding/icons/video.png"    -o /usr/share/seniorenslim/icons/video.png
curl -fsSL "${RAW}/assets/branding/icons/photos.png"   -o /usr/share/seniorenslim/icons/photos.png
curl -fsSL "${RAW}/assets/branding/icons/bank.png"     -o /usr/share/seniorenslim/icons/bank.png

echo "[6/8] Quickstart/Handleiding plaatsen…"
curl -fsSL "${RAW}/assets/docs/quickstart.md" -o /usr/share/seniorenslim/docs/quickstart.md
curl -fsSL "${RAW}/assets/docs/handleiding.md" -o /usr/share/seniorenslim/docs/handleiding.md

echo "[7/8] Browser policies…"
install -d /etc/chromium/policies/managed
curl -fsSL "${RAW}/config/apps/chromium_policies.json"   -o /etc/chromium/policies/managed/seniorenslim.json

FIREFOX_POLICY_DIR=""
if command -v firefox-esr >/dev/null 2>&1; then
  FIREFOX_POLICY_DIR="/usr/lib/firefox-esr/distribution"
elif [ -d /usr/lib/firefox/distribution ]; then
  FIREFOX_POLICY_DIR="/usr/lib/firefox/distribution"
else
  FIREFOX_POLICY_DIR="/etc/firefox/policies"
fi

echo "Firefox-policies plaatsen in ${FIREFOX_POLICY_DIR}…"
install -d "${FIREFOX_POLICY_DIR}"
curl -fsSL "${RAW}/config/apps/firefox_policies.json"     -o "${FIREFOX_POLICY_DIR}/policies.json"

echo "[8/8] Desktop-skeleton naar /etc/skel…"
install -d /etc/skel/Desktop /etc/skel/.config/autostart
for f in Internet.desktop E-mail.desktop Videobellen.desktop Fotos.desktop Bankieren.desktop; do
  curl -fsSL "${RAW}/config/desktop/skeleton/Desktop/${f}" -o "/etc/skel/Desktop/${f}"
done
curl -fsSL "${RAW}/config/desktop/skeleton/.config/autostart/seniorenslim-welcome.desktop"   -o /etc/skel/.config/autostart/seniorenslim-welcome.desktop

chmod +x /etc/skel/Desktop/*.desktop /etc/skel/.config/autostart/*.desktop || true

echo "Klaar ✅ – Maak nu een nieuw gebruikersaccount voor de eindgebruiker."
