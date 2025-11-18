variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Map of AZ to CIDR for public subnets"
  type        = map(string)
}

variable "private_subnet_cidrs" {
  description = "Map of AZ to CIDR for private subnets"
  type        = map(string)
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
