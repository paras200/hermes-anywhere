output "public_ipv4" {
  value = aws_lightsail_instance.hermes.public_ip_address
}

output "ssh_command" {
  value = "ssh admin@${aws_lightsail_instance.hermes.public_ip_address}"
}

output "dashboard_url" {
  value = "http://${aws_lightsail_instance.hermes.public_ip_address}:9119"
}
