terraform {
  required_version = ">= 1.5.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.48"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "hermes" {
  name       = "hermes-anywhere-${var.name}"
  public_key = var.ssh_public_key
}

resource "hcloud_server" "hermes" {
  name        = var.name
  image       = "debian-12"
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.hermes.id]

  user_data = templatefile("${path.module}/../../cloud-init/hermes.cloud-config.yaml.tpl", {
    hermes_version         = var.hermes_version
    hermes_model           = var.hermes_model
    hermes_fallback_model  = var.hermes_fallback_model
    openrouter_api_key     = var.openrouter_api_key
    telegram_bot_token     = var.telegram_bot_token
    telegram_allowed_users = var.telegram_allowed_users
    repo_owner             = var.repo_owner
    repo_name              = var.repo_name
  })

  labels = {
    project = "hermes-anywhere"
  }
}

resource "hcloud_firewall" "hermes" {
  name = "hermes-${var.name}"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.ssh_allowed_cidrs
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "9119"
    source_ips = var.dashboard_allowed_cidrs
  }
}

resource "hcloud_firewall_attachment" "hermes" {
  firewall_id = hcloud_firewall.hermes.id
  server_ids  = [hcloud_server.hermes.id]
}
