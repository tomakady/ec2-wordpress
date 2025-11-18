# IAM role
resource "aws_iam_role" "ec2" {
  name = "${var.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags
}

# IAM policy to read secrets
resource "aws_iam_role_policy" "ec2_secrets" {
  name = "${var.name_prefix}-ec2-secrets-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = var.db_secret_arn
    }]
  })
}


# Instance profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# EC2 instance
resource "aws_instance" "wordpress" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data/bootstrap.sh", {
    region         = var.region
    rds_endpoint   = var.rds_endpoint
    db_name        = var.db_name
    db_secret_name = var.db_secret_name
  })

  user_data_replace_on_change = true

  tags = merge(
    var.common_tags,
    { Name = "${var.name_prefix}-wordpress" }
  )
}

# Target group attachment
resource "aws_lb_target_group_attachment" "wordpress" {
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.wordpress.id
  port             = 80
}
