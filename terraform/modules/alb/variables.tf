variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}
variable "health_check_path" {
  description = "Path for ALB health check"
  type        = string
  default     = "/"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}