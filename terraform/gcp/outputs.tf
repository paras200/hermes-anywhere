output "public_ipv4" {
  value = google_compute_instance.hermes.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  value = "ssh ${var.ssh_username}@${google_compute_instance.hermes.network_interface[0].access_config[0].nat_ip}"
}

output "dashboard_url" {
  value = "http://${google_compute_instance.hermes.network_interface[0].access_config[0].nat_ip}:9119"
}
