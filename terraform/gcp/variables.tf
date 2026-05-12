variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region, e.g. us-central1, europe-west1."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone, e.g. us-central1-a."
  type        = string
  default     = "us-central1-a"
}

variable "name" {
  type    = string
  default = "hermes"
}

variable "machine_type" {
  description = "GCE machine type. e2-small (~$13/mo) or e2-medium (~$25/mo). e2-micro is free-tier eligible but only 1 GB RAM = too small for Hermes."
  type        = string
  default     = "e2-small"
}

variable "boot_disk_gb" {
  type    = number
  default = 30
}

variable "ssh_username" {
  description = "Linux username on the VM. Free choice — defaults to 'hermes'."
  type        = string
  default     = "hermes"
}

variable "ssh_public_key" {
  type = string
}

variable "ssh_allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "dashboard_allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "hermes_version" {
  type    = string
  default = "latest"
}

variable "hermes_model" {
  description = "OpenRouter model slug. Default is a free model so deploys cost $0; override to any OpenRouter slug. Browse: https://openrouter.ai/models"
  type        = string
  default     = "openai/gpt-oss-120b:free"
}

variable "openrouter_api_key" {
  type      = string
  sensitive = true
}

variable "telegram_bot_token" {
  type      = string
  default   = ""
  sensitive = true
}

variable "telegram_allowed_users" {
  type    = string
  default = ""
}

variable "repo_owner" {
  type    = string
  default = "paras200"
}

variable "repo_name" {
  type    = string
  default = "hermes-anywhere"
}
