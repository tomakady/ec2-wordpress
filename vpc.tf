# ---------------------------
# VPC
# ---------------------------
resource "aws_vpc" "this" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "wp-vpc"
  }
}

# ---------------------------
# Subnets
# ---------------------------

# Public subnets (auto-assign public IPs)
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

# Private subnets
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

# ---------------------------
# Internet + NAT
# ---------------------------

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "wp-igw"
  }
}

# Elastic IP for NAT
resource "aws_eip" "eip" {
  domain = "vpc"

  tags = {
    Name = "wp-nat-eip"
  }
}

# NAT Gateway (must live in a PUBLIC subnet)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = "wp-nat"
  }
}

# ---------------------------
# Route Tables
# ---------------------------

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

# Use the VPC's auto-created MAIN route table as the PRIVATE route table
resource "aws_default_route_table" "private" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  # Default route for private subnets -> NAT
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt (main)"
  }
}

# ---------------------------
# Route table associations
# ---------------------------

# Public subnets use the public RT (IGW)
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

# Private subnets use the MAIN (now private) RT (NAT)
resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_default_route_table.private.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_default_route_table.private.id
}

# ---------------------------
# Security groups
# ---------------------------

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
