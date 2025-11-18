# Random password
resource "random_password" "rds" {
  length           = 24
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#$%&()*+,-.:;<=>?[]^_{|}~"
}

# Secrets Manager secret
resource "aws_secretsmanager_secret" "rds" {
  name = var.db_secret_name

  tags = merge(
    var.common_tags,
    { Name = var.db_secret_name }
  )
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.rds.result
  })
}

# Force delete on destroy
resource "null_resource" "force_delete_secret" {
  triggers = {
    secret_arn = aws_secretsmanager_secret.rds.arn
    region     = var.region
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws secretsmanager delete-secret --secret-id ${self.triggers.secret_arn} --force-delete-without-recovery --region ${self.triggers.region}"
  }

  depends_on = [aws_secretsmanager_secret.rds]
}

# DB subnet group
resource "aws_db_subnet_group" "rds" {
  name       = "${var.name_prefix}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(
    var.common_tags,
    { Name = "${var.name_prefix}-rds-subnet-group" }
  )
}

# RDS instance
resource "aws_db_instance" "rds" {
  identifier        = var.db_identifier
  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = var.db_storage_type

  db_name  = var.db_name
  username = var.db_username
  password = random_password.rds.result

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [var.rds_security_group_id]

  backup_retention_period   = var.db_backup_retention
  multi_az                  = var.db_multi_az
  skip_final_snapshot       = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : var.db_final_snapshot_id
  publicly_accessible       = false
  deletion_protection       = false
  apply_immediately         = true

  tags = merge(
    var.common_tags,
    { Name = "${var.name_prefix}-rds" }
  )
}
