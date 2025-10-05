# Basic outputs
output "ec2_public_dns" {
  value = aws_instance.wordpress.public_dns
}

output "ec2_subnet_id" {
  value = aws_instance.wordpress.subnet_id
}

output "public_rt_routes" {
  value = aws_route_table.public.route
}

output "ec2_attached_sg_ids" {
  value = aws_instance.wordpress.vpc_security_group_ids
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "public_associations" {
  value = { for k, v in aws_route_table_association.public : v.subnet_id => v.route_table_id }
}

# WordPress access outputs
output "wordpress_url" {
  description = "WordPress site URL"
  value       = "http://${aws_instance.wordpress.public_dns}"
}

output "wordpress_admin_url" {
  description = "WordPress admin dashboard URL"
  value       = "http://${aws_instance.wordpress.public_dns}/wp-admin"
}

output "wordpress_admin_user" {
  description = "WordPress admin username"
  value       = var.wp_admin_user
}

output "wordpress_admin_password" {
  description = "WordPress admin password"
  value       = var.wp_admin_password
  sensitive   = true
}

output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.rds_instance.address
}

output "ssh_command" {
  description = "SSH command to connect to EC2 instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.wordpress.public_dns}"
}

output "check_bootstrap_log" {
  description = "Command to check bootstrap progress"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.wordpress.public_dns} 'sudo tail -f /var/log/bootstrap.log'"
}
output "ec2_public_ip" {
  value = aws_instance.wordpress.public_ip
}
