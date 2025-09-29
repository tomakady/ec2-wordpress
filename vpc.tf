locals {
  name = var.name_prefix
}

# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    { Name = "${local.name}-vpc" },
    var.common_tags
  )
}

# Public subnets
resource "aws_subnet" "public" {
  for_each                = var.public_subnet_cidrs
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    { Name = "${local.name}-public-${substr(each.key, length(each.key) - 1, 1)}" }
  )
}

# Private subnets
resource "aws_subnet" "private" {
  for_each          = var.private_subnet_cidrs
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(
    var.common_tags,
    { Name = "${local.name}-private-${substr(each.key, length(each.key) - 1, 1)}" }
  )
}

# IGW + NAT
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    { Name = "${local.name}-igw" },
    var.common_tags
  )
}

resource "aws_eip" "eip" {
  domain = "vpc"
  tags = merge(
    { Name = "${local.name}-nat-eip" },
    var.common_tags
  )
}

locals {
  nat_az        = var.azs[0]
  nat_public_id = aws_subnet.public[local.nat_az].id
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = local.nat_public_id

  tags = merge(
    { Name = "${local.name}-nat" },
    var.common_tags
  )
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = var.any_ipv4_cidr # "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    { Name = "${local.name}-public-rt" },
    var.common_tags
  )
}

# Use main route table for private routes
resource "aws_default_route_table" "private" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  route {
    cidr_block     = var.any_ipv4_cidr
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(
    { Name = "${local.name}-private-rt-main" },
    var.common_tags
  )
}

# Associations
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_default_route_table.private.id
}

# EC2 SG (SSH + HTTP)
resource "aws_security_group" "allow_ssh" {
  name        = "${local.name}-web-sg"
  description = "Allow SSH and HTTP inbound"
  vpc_id      = aws_vpc.this.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = var.ssh_port # 22
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = var.http_port # 80
    to_port     = var.http_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.egress_ipv4_cidrs
    # ipv6_cidr_blocks = var.egress_ipv6_cidrs
  }

  tags = merge(
    var.common_tags,
    { Name = "${local.name}-web-sg" }
  )
}

/*

# VPC

resource "aws_vpc" "this" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "wp-vpc"
  }
}

# Subnets

# Public subnets (auto-assign public IPs)

resource "aws_subnet" "public" {
  for_each                = var.public_subnet_cidrs
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true
  tags = {
    Name = "wp-public-${substr(each.key, length(each.key) - 1, 1)}"
  }
}

# Private subnets

resource "aws_subnet" "private" {
  for_each          = var.private_subnet_cidrs
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value
  tags = {
    Name = "wp-private-${substr(each.key, length(each.key) - 1, 1)}"
  }
}

# Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "wp-igw" }
}

# Elastic IP for NAT
resource "aws_eip" "eip" {
  domain = "vpc"
  tags   = { Name = "wp-nat-eip" }
}

# NAT Gateway

locals {
  nat_az        = var.azs[0]
  nat_public_id = aws_subnet.public[local.nat_az].id
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = local.nat_public_id
  tags          = { Name = "wp-nat" }
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

# Use VPC's auto-created main route table as the private route table
resource "aws_default_route_table" "private" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt (main)"
  }
}

# Route table associations

# Public subnets
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private subnets
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_default_route_table.private.id
}

# Security groups

# Allow SSH/HTTP to instances in this VPC (attach to EC2/ALB as needed)
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

#old
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.100.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "wp-public-1"
  }
}
resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.100.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "wp-public-2"
  }
}
*/


/*
resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.100.3.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "wp-private-1"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.100.4.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name = "wp-private-2"
  }
}

*/

/*

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = "wp-nat"
  }
}

*/

/*

# Public route table (0.0.0.0/0 -> IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

*/
