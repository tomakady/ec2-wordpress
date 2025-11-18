# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    { Name = "${var.name_prefix}-vpc" },
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
    { Name = "${var.name_prefix}-public-${substr(each.key, length(each.key) - 1, 1)}" }
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
    { Name = "${var.name_prefix}-private-${substr(each.key, length(each.key) - 1, 1)}" }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    { Name = "${var.name_prefix}-igw" },
    var.common_tags
  )
}

# Elastic IP for NAT
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    { Name = "${var.name_prefix}-nat-eip" },
    var.common_tags
  )
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[var.azs[0]].id

  tags = merge(
    { Name = "${var.name_prefix}-nat" },
    var.common_tags
  )
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    { Name = "${var.name_prefix}-public-rt" },
    var.common_tags
  )
}

# Private route table (default)
resource "aws_default_route_table" "private" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(
    { Name = "${var.name_prefix}-private-rt" },
    var.common_tags
  )
}

# Route table associations
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
