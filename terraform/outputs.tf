# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

# EC2 Outputs
output "ec2_public_ip" {
  description = "EC2 public IP"
  value       = module.ec2.public_ip
}

output "ec2_public_dns" {
  description = "EC2 public DNS"
  value       = module.ec2.public_dns
}

output "wordpress_url" {
  description = "WordPress site URL"
  value       = "http://${module.ec2.public_dns}"
}

output "wordpress_admin_url" {
  description = "WordPress admin URL"
  value       = "http://${module.ec2.public_dns}/wp-admin"
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.rds_endpoint
}

# Commands
output "ssh_command" {
  description = "SSH command"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.ec2.public_dns}"
}

output "check_bootstrap_log" {
  description = "Check bootstrap log"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.ec2.public_dns} 'sudo tail -f /var/log/bootstrap.log'"
}

### ALB Outputs

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_zone_id" {
  value = module.alb.alb_zone_id
}

output "target_group_arn" {
  value = module.alb.target_group_arn
}

output "alb_arn" {
  value = module.alb.alb_arn
}
