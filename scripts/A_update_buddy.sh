#!/usr/bin/env bash
set -euo pipefail
[ "${EUID:-$(id -u)}" -eq 0 ] || { echo "Run as root (sudo)"; exit 1; }

install -d /usr/local/bin
cat >/usr/local/bin/seniorenslim-update-buddy <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
if command -v notify-send >/dev/null 2>&1; then
  sudo -u "$(logname 2>/dev/null || echo root)" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u ${SUDO_USER:-0})/bus   notify-send "SeniorenSlim" "Updates zijn geïnstalleerd."
fi
EOF
chmod +x /usr/local/bin/seniorenslim-update-buddy

cat >/etc/systemd/system/seniorenslim-update-buddy.service <<'EOF'
[Unit]
Description=SeniorenSlim Update Buddy

[Service]
Type=oneshot
ExecStart=/usr/local/bin/seniorenslim-update-buddy
EOF

cat >/etc/systemd/system/seniorenslim-update-buddy.timer <<'EOF'
[Unit]
Description=Run Update Buddy dagelijks om 10:00

[Timer]
OnCalendar=*-*-* 10:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now seniorenslim-update-buddy.timer
echo "Update Buddy geactiveerd ✅"
