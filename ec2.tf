#EC2
resource "aws_instance" "wordpress" {
  ami           = data.aws_ssm_parameter.al2023.value
  instance_type = "t3.micro"
  # ...subnet_id, vpc_security_group_ids, key_name, user_data, etc.
}
