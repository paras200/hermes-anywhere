#!/usr/bin/env bash
# Install the daily Hermes-version-check systemd timer on a Linux host.
#
# Runs notify-update.sh once a day at 09:00 local time. Sends a Telegram
# message (if configured) the first time a new release is detected.
#
# Run as root on the VM:
#   sudo bash /opt/hermes-anywhere/scripts/install-cron.sh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)." >&2
  exit 1
fi

REPO_ROOT="${HERMES_ANYWHERE_DIR:-/opt/hermes-anywhere}"

cat >/etc/systemd/system/hermes-update-check.service <<EOF
[Unit]
Description=Hermes Anywhere — daily upstream version check
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$REPO_ROOT/scripts/notify-update.sh
StandardOutput=journal
StandardError=journal
EOF

cat >/etc/systemd/system/hermes-update-check.timer <<'EOF'
[Unit]
Description=Run hermes-update-check daily at 09:00

[Timer]
OnCalendar=*-*-* 09:00:00
RandomizedDelaySec=30m
Persistent=true
Unit=hermes-update-check.service

[Install]
WantedBy=timers.target
EOF

chmod 644 /etc/systemd/system/hermes-update-check.{service,timer}

systemctl daemon-reload
systemctl enable --now hermes-update-check.timer

echo "✓ Installed systemd timer hermes-update-check.timer"
echo ""
echo "Verify with:"
echo "  systemctl status hermes-update-check.timer"
echo "  systemctl list-timers hermes-update-check.timer"
echo ""
echo "Run the check once now (without waiting for 09:00):"
echo "  sudo systemctl start hermes-update-check.service"
echo "  sudo journalctl -u hermes-update-check.service --since '5 min ago'"
