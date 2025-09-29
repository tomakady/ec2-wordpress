# DB instance
resource "aws_db_instance" "rds_instance" {
  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  identifier = var.db_identifier
  db_name    = var.db_name

  username = var.db_username
  password = random_password.rds.result

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]

  backup_retention_period = var.db_backup_retention
  multi_az                = var.db_multi_az
  storage_type            = var.db_storage_type

  skip_final_snapshot       = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_final_snapshot_id

  publicly_accessible = false
  deletion_protection = false
  apply_immediately   = true

  tags = merge(
    { Name = "${var.name_prefix}-rds" },
    var.common_tags
  )
}

# Secret and password
resource "random_password" "rds" {
  length           = 24
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#$%&()*+,-.:;<=>?[]^_{|}~"
}

resource "aws_secretsmanager_secret" "rds_master" {
  name = var.db_secret_name
  # lifecycle { prevent_destroy = true }
  # recovery_window_in_days = 7

  /*
  #  recovery_window_in_days = 7-30
  ^ Sets a recovery window so a secret can be restored if deleted between 7 and 30 days
  Syntax for recovery:
  aws secretsmanager restore-secret \
  --secret-id wp/rds-master <-- name of secret to restore
  Found in terraform.tfvars under db_secret_name
  */
}

resource "aws_secretsmanager_secret_version" "rds_master_v" {
  secret_id = aws_secretsmanager_secret.rds_master.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.rds.result
  })
}

# Force immediate deletion at destroy (so the same name can be recreated instantly)
resource "null_resource" "force_delete_secret_on_destroy" {
  triggers = {
    secret_arn = aws_secretsmanager_secret.rds_master.arn
    region     = var.region
  }
  provisioner "local-exec" {
    when    = destroy
    command = "aws secretsmanager delete-secret --secret-id ${self.triggers.secret_arn} --force-delete-without-recovery --region ${self.triggers.region}"
  }
  depends_on = [aws_secretsmanager_secret.rds_master]
}

# DB subnet group (all private subnets)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id]
  tags       = { Name = "rds-subnet-group" }
}

# RDS SG (allow MySQL only from EC2 SG)
resource "aws_security_group" "rds_security_group" {
  name        = "rds-security-group"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "RDS Security Group" }
}

resource "aws_security_group_rule" "rds_from_ec2" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds_security_group.id
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.allow_ssh.id
  description              = "MySQL from EC2 instances"
}

/*
# RDS password in AWS Secrets Manager

resource "random_password" "rds" {
  length  = 24
  special = true
}

resource "aws_secretsmanager_secret" "rds_master" {
  name                    = "wp/rds-master"
  recovery_window_in_days = 7
  lifecycle { prevent_destroy = true }
}

resource "aws_secretsmanager_secret_version" "rds_master_v" {
  secret_id = aws_secretsmanager_secret.rds_master.id
  secret_string = jsonencode({
    username = "wordpress"
    password = random_password.rds.result
  })

  lifecycle { ignore_changes = [secret_string] }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id]
  tags = {
    Name = "rds-subnet-group"
  }
}

# RDS instance

resource "aws_db_instance" "rds_instance" {
  engine                    = "mysql"
  engine_version            = "8.0"
  instance_class            = "db.t3.micro"
  allocated_storage         = 20
  skip_final_snapshot       = true
  final_snapshot_identifier = "my-final-snapshot"
  identifier                = "my-rds-instance"

  db_name  = "wordpress_db"
  username = "wordpress"
  password = random_password.rds.result

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]

  tags = {
    Name = "RDS Instance"
  }
}

# RDS security group

resource "aws_security_group" "rds_security_group" {
  name        = "rds-security-group"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.this.id

  # No ingress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS Security Group"
  }
}

# Only allow MySQL from  EC2 SG
resource "aws_security_group_rule" "rds_from_ec2" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds_security_group.id
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.allow_ssh.id
  description              = "MySQL from EC2 instances"
}



# old
# RDS subnet
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]
}

# RDS instance
resource "aws_db_instance" "rds_instance" {
  engine                    = "mysql"
  engine_version            = "5.7"
  skip_final_snapshot       = true
  final_snapshot_identifier = "my-final-snapshot"
  instance_class            = "db.t3.micro"
  allocated_storage         = 20
  identifier                = "my-rds-instance"
  db_name                   = "wordpress_db"
  username                  = "tomakady"
  password                  = "tomakady123!"
  db_subnet_group_name      = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids    = [aws_security_group.rds_security_group.id]

  tags = {
    Name = "RDS Instance"
  }
}

# RDS security group
resource "aws_security_group" "rds_security_group" {
  name        = "rds-security-group"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "RDS Security Group"
  }
}

# RDS subnet group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id] # was [private1.id, private2.id]

  tags = {
    Name = "rds-subnet-group"
  }
}

*/
