variable "hcloud_token" {
  description = "Hetzner Cloud API token. Get one at https://console.hetzner.cloud → Security → API Tokens."
  type        = string
  sensitive   = true
}

variable "name" {
  description = "Server name (also used for SSH key + firewall labels)."
  type        = string
  default     = "hermes"
}

variable "server_type" {
  description = "Hetzner server type. CX22 (2 vCPU, 4GB, €4.49/mo) is the recommended floor."
  type        = string
  default     = "cx22"
}

variable "location" {
  description = "Hetzner location. fsn1 (Falkenstein), nbg1 (Nuremberg), hel1 (Helsinki), ash (Ashburn US), hil (Hillsboro US)."
  type        = string
  default     = "fsn1"
}

variable "ssh_public_key" {
  description = "SSH public key (contents of ~/.ssh/id_ed25519.pub)."
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH. Default permissive — narrow for production."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "dashboard_allowed_cidrs" {
  description = "CIDR blocks allowed to reach the Hermes dashboard on :9119."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "hermes_version" {
  description = "Hermes Docker image tag. Browse: https://hub.docker.com/r/nousresearch/hermes-agent/tags"
  type        = string
  default     = "latest"
}

variable "hermes_model" {
  description = "OpenRouter model slug. Default is a free model so deploys cost $0; override to any OpenRouter slug. Browse: https://openrouter.ai/models"
  type        = string
  default     = "openai/gpt-oss-120b:free"
}

variable "hermes_fallback_model" {
  description = "OpenRouter slug used as backup when the primary fails (rate limit, 5xx, conn errors). Empty string disables the fallback chain. Pick another `:free` slug to keep deploys at $0."
  type        = string
  default     = "z-ai/glm-4.5-air:free"
}

variable "openrouter_api_key" {
  description = "OpenRouter API key (https://openrouter.ai/keys)."
  type        = string
  sensitive   = true
}

variable "telegram_bot_token" {
  description = "Optional Telegram bot token from @BotFather."
  type        = string
  default     = ""
  sensitive   = true
}

variable "telegram_allowed_users" {
  description = "Optional comma-separated Telegram user IDs allowed to message the bot."
  type        = string
  default     = ""
}

variable "repo_owner" {
  description = "GitHub owner of the hermes-anywhere repo to clone on the VM."
  type        = string
  default     = "paras200"
}

variable "repo_name" {
  description = "GitHub repo name."
  type        = string
  default     = "hermes-anywhere"
}
