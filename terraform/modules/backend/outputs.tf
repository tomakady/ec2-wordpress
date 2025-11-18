output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.rds.address
}

output "rds_arn" {
  description = "RDS ARN"
  value       = aws_db_instance.rds.arn
}

output "db_secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.rds.arn
}

output "db_secret_name" {
  description = "Secrets Manager secret name"
  value       = aws_secretsmanager_secret.rds.name
}
