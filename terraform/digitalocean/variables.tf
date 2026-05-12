variable "do_token" {
  description = "DigitalOcean API token. Create at https://cloud.digitalocean.com/account/api/tokens (Read & Write)."
  type        = string
  sensitive   = true
}

variable "name" {
  type    = string
  default = "hermes"
}

variable "droplet_size" {
  description = "Droplet slug. s-2vcpu-4gb is $24/mo. s-1vcpu-2gb ($12) works for low load."
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "region" {
  description = "DO region slug: nyc1, nyc3, sfo3, ams3, fra1, lon1, sgp1, blr1, syd1, tor1."
  type        = string
  default     = "nyc3"
}

variable "ssh_public_key" {
  type = string
}

variable "ssh_allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0", "::/0"]
}

variable "dashboard_allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0", "::/0"]
}

variable "hermes_version" {
  type    = string
  default = "latest"
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
