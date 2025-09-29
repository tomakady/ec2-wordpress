# EC2
resource "aws_instance" "wordpress" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public[var.azs[0]].id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  iam_instance_profile        = aws_iam_instance_profile.wp_ec2_profile.name
  associate_public_ip_address = true
  tags                        = { Name = var.ec2_name }

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    region            = var.region
    rds_endpoint      = aws_db_instance.rds_instance.address
    db_name           = var.db_name
    wp_site_title     = var.wp_site_title
    wp_admin_user     = var.wp_admin_user
    wp_admin_password = var.wp_admin_password
    wp_admin_email    = var.wp_admin_email
    db_secret_name    = var.db_secret_name
  })
  user_data_replace_on_change = true

  depends_on = [
    aws_db_instance.rds_instance,
    aws_secretsmanager_secret_version.rds_master_v
  ]
}

# IAM role so EC2 can read the secret
resource "aws_iam_role" "wp_ec2_role" {
  name = "wp-ec2-secrets-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "wp_ec2_read_secret" {
  name = "read-wp-rds-secret"
  role = aws_iam_role.wp_ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = aws_secretsmanager_secret.rds_master.arn
    }]
  })
}

resource "aws_iam_instance_profile" "wp_ec2_profile" {
  name = "wp-ec2-secrets-profile"
  role = aws_iam_role.wp_ec2_role.name
}


/*
  # For wordpress EC2 instance

  # count = #number of instances you want to create
  tags { 
    Name = "wp-ec2-wordpress-${count.index + 1}"
  }

  # For each loops

  dev1 = {
    instance_type = "t3.micro"
    ami_id        = "ami-dev1"
  }

  dev2 = {
    instance_type = "t2.micro"
    ami_id        = "ami-dev2"
  }

  dev3 = {
    instance_type = "t3.micro"
    ami_id        = "ami-dev3"
  }

  resource "aws_instance" "this" {
    for_each = local.instances

    instance_type = each.value.instance_type
    ami           = each.value.ami_id
  }

    tags {
      Name = each.key
    }


  */


/* 
#EC2

resource "aws_instance" "wordpress" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = aws_subnet.public[var.azs[0]].id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  iam_instance_profile   = aws_iam_instance_profile.wp_ec2_profile.name
  tags                   = { Name = "wp-ec2-wordpress" }

  # ADDED: cloud-init bootstrap
  user_data = <<-BASH
    #!/usr/bin/env bash
    set -euo pipefail

    REGION="eu-west-2"
    RDS_ENDPOINT="${aws_db_instance.rds_instance.address}"

    # Install deps
    dnf install -y docker awscli jq
    systemctl enable --now docker

    # Install Docker Compose v2 (x86_64)
    mkdir -p /usr/libexec/docker/cli-plugins
    curl -sSL -o /usr/libexec/docker/cli-plugins/docker-compose \
      "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64"
    chmod +x /usr/libexec/docker/cli-plugins/docker-compose

    # Allow ec2-user to use docker
    usermod -aG docker ec2-user

    # Fetch DB creds from Secrets Manager
    SECRET_JSON=$(aws secretsmanager get-secret-value \
      --secret-id "wp/rds-master" \
      --region "$REGION" \
      --query SecretString --output text)
    DB_USER=$(echo "$SECRET_JSON" | jq -r .username)
    DB_PASS=$(echo "$SECRET_JSON" | jq -r .password)

    # Write .env for Compose (note $$ to defer to bash)
    cat >/home/ec2-user/.env <<EOF
    WORDPRESS_DB_HOST=$${RDS_ENDPOINT}:3306
    WORDPRESS_DB_USER=$${DB_USER}
    WORDPRESS_DB_PASSWORD=$${DB_PASS}
    WORDPRESS_DB_NAME=wordpress_db
    EOF
    chown ec2-user:ec2-user /home/ec2-user/.env
    chmod 600 /home/ec2-user/.env

    # Minimal docker-compose.yml
    cat >/home/ec2-user/docker-compose.yml <<EOF
    version: "3"
    services:
      wordpress:
        image: wordpress:latest
        container_name: wordpress
        ports:
          - "80:80"
        env_file: /home/ec2-user/.env
        volumes:
          - wordpress_data:/var/www/html
        restart: unless-stopped
    volumes:
      wordpress_data:
    EOF
    chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml

    # Bring it up
    sudo -u ec2-user docker compose -f /home/ec2-user/docker-compose.yml up -d
  BASH

  # Ensure RDS endpoint exists before running user_data
  depends_on = [aws_db_instance.rds_instance]
}

resource "aws_iam_role" "wp_ec2_role" {
  name = "wp-ec2-secrets-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "wp_ec2_read_secret" {
  name = "read-wp-rds-secret"
  role = aws_iam_role.wp_ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = aws_secretsmanager_secret.rds_master.arn
    }]
  })
}

resource "aws_iam_instance_profile" "wp_ec2_profile" {
  name = "wp-ec2-secrets-profile"
  role = aws_iam_role.wp_ec2_role.name
}



# old
# Generate a new RSA key locally
resource "tls_private_key" "wp" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create an AWS key pair from its public half
resource "aws_key_pair" "wp" {
  key_name   = "wp-key"
  public_key = tls_private_key.wp.public_key_openssh
}

# Save the private key to disk securely
resource "local_sensitive_file" "wp_private_key" {
  content         = tls_private_key.wp.private_key_pem
  filename        = "${path.module}/wp-key.pem"
  file_permission = "0400"
} */
