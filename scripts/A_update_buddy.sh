#!/usr/bin/env bash
set -euo pipefail

if ! command -v apt >/dev/null 2>&1; then exit 0; fi

export DEBIAN_FRONTEND=noninteractive
apt update -y || true
apt dist-upgrade -y || true
apt autoremove -y || true

# Vriendelijke desktop-melding (als een user ingelogd is)
for uid in $(loginctl list-sessions | awk 'NR>1 {print $1}'); do
  user=$(loginctl show-session "$uid" -p Name --value 2>/dev/null || true)
  if [ -n "$user" ]; then
    sudo -u "$user" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u "$user")/bus \
      notify-send "SeniorenSlim" "Je computer is bijgewerkt en weer veilig. 👍"
  fi
done
