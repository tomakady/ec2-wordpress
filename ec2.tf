#EC2
resource "aws_instance" "wordpress" {
  ami           = data.aws_ssm_parameter.al2023.value
  instance_type = "t3.micro"
  key_name      = aws_key_pair.wp.key_name
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

# Save the private key to disk (optional but typical)
resource "local_file" "wp_private_key" {
  content         = tls_private_key.wp.private_key_pem
  filename        = "${path.module}/wp-key.pem"
  file_permission = "0400"
}



/*
Original Wordpress EC2 / Key Pair Code 

resource "aws_instance" "wordpress" {
  ami           = data.aws_ssm_parameter.al2023.value
  instance_type = "t3.micro"
  # ...subnet_id, vpc_security_group_ids, key_name, user_data, etc.
}

# Generate new private key 
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
}

# Generate a key-pair with above key
resource "aws_key_pair" "deployer" {
  key_name   = "wp-key"
  public_key = tls_private_key.my_key.public_key_openssh
}

# Saving Key Pair
resource "null_resource" "save_key_pair" {
  provisioner "local-exec" {
    command = "echo  ${tls_private_key.my_key.private_key_pem} > wp-key.pem"
  }
}



*/
