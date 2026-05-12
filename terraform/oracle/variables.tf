variable "tenancy_ocid" {
  description = "OCID of your tenancy. Profile menu → Tenancy."
  type        = string
}

variable "user_ocid" {
  description = "OCID of your user. Profile menu → My Profile."
  type        = string
}

variable "fingerprint" {
  description = "API key fingerprint. My Profile → API Keys → Fingerprint column."
  type        = string
}

variable "private_key_path" {
  description = "Path to the OCI API private key (PEM)."
  type        = string
}

variable "region" {
  description = "OCI region, e.g. us-ashburn-1, eu-frankfurt-1, ap-mumbai-1."
  type        = string
  default     = "us-ashburn-1"
}

variable "compartment_ocid" {
  description = "OCID of the compartment to deploy into. Use the tenancy OCID for the root compartment."
  type        = string
}

variable "availability_domain" {
  description = "Availability domain name, e.g. 'AbCD:US-ASHBURN-AD-1'. Run: oci iam availability-domain list."
  type        = string
}

variable "name" {
  type    = string
  default = "hermes"
}

variable "ocpus" {
  description = "OCPUs for the A1 Flex instance. Free tier: total 4 OCPUs across all A1 instances."
  type        = number
  default     = 2
}

variable "memory_in_gbs" {
  description = "RAM in GB. Free tier: total 24 GB across all A1 instances."
  type        = number
  default     = 12
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
