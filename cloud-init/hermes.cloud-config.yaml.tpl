#cloud-config
# Hermes Anywhere — cloud-init bootstrap (provider-agnostic).
#
# Rendered by Terraform at deploy time. Placeholders ${VAR} are filled by
# the per-cloud module via templatefile() / cloudinit_config.
#
# Tested on: Debian 12, Ubuntu 22.04/24.04, Oracle Linux 8 (ARM A1).

package_update: true
package_upgrade: false

packages:
  - ca-certificates
  - curl
  - git
  - gnupg
  - ufw

write_files:
  - path: /opt/hermes-anywhere/.env
    permissions: "0600"
    owner: root:root
    content: |
      HERMES_VERSION=${hermes_version}
      DASHBOARD_BIND=0.0.0.0
      OPENROUTER_API_KEY=${openrouter_api_key}
      TELEGRAM_BOT_TOKEN=${telegram_bot_token}
      TELEGRAM_ALLOWED_USERS=${telegram_allowed_users}

  - path: /etc/systemd/system/hermes.service
    permissions: "0644"
    content: |
      [Unit]
      Description=Hermes Agent (docker compose)
      Requires=docker.service
      After=docker.service network-online.target
      Wants=network-online.target

      [Service]
      Type=oneshot
      RemainAfterExit=yes
      WorkingDirectory=/opt/hermes-anywhere
      ExecStartPre=/usr/bin/docker compose pull
      ExecStart=/usr/bin/docker compose up -d
      ExecStop=/usr/bin/docker compose down

      [Install]
      WantedBy=multi-user.target

runcmd:
  # Install Docker Engine (official convenience script — works on Debian/Ubuntu/RHEL family)
  - curl -fsSL https://get.docker.com | sh
  - systemctl enable --now docker

  # Clone the Hermes Anywhere repo (public). Pin to a tag in production.
  - git clone --depth 1 https://github.com/${repo_owner}/${repo_name}.git /opt/hermes-anywhere
  - mkdir -p /opt/hermes-anywhere/hermes-data
  - chmod 700 /opt/hermes-anywhere/hermes-data

  # Open firewall: SSH + dashboard. (Cloud security groups are the primary gate.)
  - ufw --force enable
  - ufw allow 22/tcp
  - ufw allow 9119/tcp

  # Start Hermes via systemd so it survives reboots.
  - systemctl daemon-reload
  - systemctl enable --now hermes.service

final_message: "Hermes Anywhere bootstrap complete. Dashboard at http://<public-ip>:9119 in ~60s."
