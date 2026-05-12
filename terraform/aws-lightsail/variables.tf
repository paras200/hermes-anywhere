variable "region" {
  description = "AWS region. Lightsail availability_zone must be in this region."
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Lightsail AZ, e.g. us-east-1a."
  type        = string
  default     = "us-east-1a"
}

variable "name" {
  type    = string
  default = "hermes"
}

variable "bundle_id" {
  description = "Lightsail bundle. medium_3_0 = 2 vCPU/4GB/$20/mo. small_3_0 = 1 vCPU/2GB/$10/mo."
  type        = string
  default     = "medium_3_0"
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
