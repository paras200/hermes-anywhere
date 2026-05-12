terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "hermes" {
  name                    = "hermes-${var.name}-network"
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "ssh" {
  name    = "hermes-${var.name}-ssh"
  network = google_compute_network.hermes.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_allowed_cidrs
  target_tags   = ["hermes"]
}

resource "google_compute_firewall" "dashboard" {
  name    = "hermes-${var.name}-dashboard"
  network = google_compute_network.hermes.name

  allow {
    protocol = "tcp"
    ports    = ["9119"]
  }

  source_ranges = var.dashboard_allowed_cidrs
  target_tags   = ["hermes"]
}

resource "google_compute_instance" "hermes" {
  name         = var.name
  machine_type = var.machine_type
  tags         = ["hermes"]

  boot_disk {
    initialize_params {
      # Ubuntu LTS — GCP's debian-12 image ships without cloud-init, so the
      # cloud-config user-data would silently no-op there.
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = var.boot_disk_gb
    }
  }

  network_interface {
    network = google_compute_network.hermes.name
    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${var.ssh_public_key}"
    user-data = templatefile("${path.module}/../../cloud-init/hermes.cloud-config.yaml.tpl", {
      hermes_version         = var.hermes_version
      openrouter_api_key     = var.openrouter_api_key
      telegram_bot_token     = var.telegram_bot_token
      telegram_allowed_users = var.telegram_allowed_users
      repo_owner             = var.repo_owner
      repo_name              = var.repo_name
    })
  }

  labels = {
    project = "hermes-anywhere"
  }
}
