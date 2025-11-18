output "public_ip" {
  description = "Public IP"
  value       = aws_instance.wordpress.public_ip
}

output "public_dns" {
  description = "Public DNS"
  value       = aws_instance.wordpress.public_dns
}
