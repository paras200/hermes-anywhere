terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_lightsail_key_pair" "hermes" {
  name       = "hermes-anywhere-${var.name}"
  public_key = var.ssh_public_key
}

resource "aws_lightsail_instance" "hermes" {
  name              = var.name
  availability_zone = var.availability_zone
  blueprint_id      = "debian_12"
  bundle_id         = var.bundle_id
  key_pair_name     = aws_lightsail_key_pair.hermes.name

  user_data = templatefile("${path.module}/../../cloud-init/hermes.cloud-config.yaml.tpl", {
    hermes_version         = var.hermes_version
    openrouter_api_key     = var.openrouter_api_key
    telegram_bot_token     = var.telegram_bot_token
    telegram_allowed_users = var.telegram_allowed_users
    repo_owner             = var.repo_owner
    repo_name              = var.repo_name
  })

  tags = {
    project = "hermes-anywhere"
  }
}

resource "aws_lightsail_instance_public_ports" "hermes" {
  instance_name = aws_lightsail_instance.hermes.name

  port_info {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidrs     = var.ssh_allowed_cidrs
  }

  port_info {
    protocol  = "tcp"
    from_port = 9119
    to_port   = 9119
    cidrs     = var.dashboard_allowed_cidrs
  }
}
