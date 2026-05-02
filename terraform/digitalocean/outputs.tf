output "public_ipv4" {
  value = digitalocean_droplet.hermes.ipv4_address
}

output "ssh_command" {
  value = "ssh root@${digitalocean_droplet.hermes.ipv4_address}"
}

output "dashboard_url" {
  value = "http://${digitalocean_droplet.hermes.ipv4_address}:9119"
}
