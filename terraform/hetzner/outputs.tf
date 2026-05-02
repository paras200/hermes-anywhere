output "public_ipv4" {
  value       = hcloud_server.hermes.ipv4_address
  description = "Public IPv4 of the Hermes VM."
}

output "ssh_command" {
  value       = "ssh root@${hcloud_server.hermes.ipv4_address}"
  description = "SSH login command."
}

output "dashboard_url" {
  value       = "http://${hcloud_server.hermes.ipv4_address}:9119"
  description = "Hermes dashboard URL (allow ~60s for first boot)."
}
