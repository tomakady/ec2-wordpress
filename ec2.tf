#EC2
resource "aws_instance" "wordpress" {
  ami           = data.aws_ssm_parameter.al2023.value
  instance_type = "t3.micro"
  key_name      = aws_key_pair.wp.key_name

  # Ensure instance is launched in YOUR custom VPC
  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  # If you didn't enable map_public_ip_on_launch on the subnet, uncomment:
  # associate_public_ip_address = true
}

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
}
