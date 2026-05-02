terraform {
  required_version = ">= 1.5.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.40"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_ssh_key" "hermes" {
  name       = "hermes-anywhere-${var.name}"
  public_key = var.ssh_public_key
}

resource "digitalocean_droplet" "hermes" {
  name     = var.name
  image    = "debian-12-x64"
  size     = var.droplet_size
  region   = var.region
  ssh_keys = [digitalocean_ssh_key.hermes.id]

  user_data = templatefile("${path.module}/../../cloud-init/hermes.cloud-config.yaml.tpl", {
    hermes_version         = var.hermes_version
    openrouter_api_key     = var.openrouter_api_key
    telegram_bot_token     = var.telegram_bot_token
    telegram_allowed_users = var.telegram_allowed_users
    repo_owner             = var.repo_owner
    repo_name              = var.repo_name
  })

  tags = ["hermes-anywhere"]
}

resource "digitalocean_firewall" "hermes" {
  name        = "hermes-${var.name}"
  droplet_ids = [digitalocean_droplet.hermes.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.ssh_allowed_cidrs
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "9119"
    source_addresses = var.dashboard_allowed_cidrs
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
