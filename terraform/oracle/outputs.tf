output "public_ipv4" {
  value = oci_core_instance.hermes.public_ip
}

output "ssh_command" {
  value = "ssh ubuntu@${oci_core_instance.hermes.public_ip}"
}

output "dashboard_url" {
  value = "http://${oci_core_instance.hermes.public_ip}:9119"
}
