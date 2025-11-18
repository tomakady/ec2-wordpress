# EC2 instance
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}
variable "ami_id" {
  description = "Pinned AMI ID for the EC2 instance (eu-west-2)"
  type        = string
}
variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
variable "ec2_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "wp-ec2-wordpress"
}

# DB
variable "db_secret_name" {
  description = "Secrets Manager secret name for DB creds"
  type        = string
  default     = "wp/rds-master"
}
variable "secret_env" {
  description = "If true, delete Secrets Manager secrets immediately on destroy so re-apply can reuse the same name."
  type        = bool
  default     = true
}
variable "db_identifier" {
  description = "RDS instance identifier"
  type        = string
  default     = "my-rds-instance"
}
variable "db_name" {
  description = "Initial DB name"
  type        = string
  default     = "wordpress_db"
}
variable "db_username" {
  description = "DB master username"
  type        = string
  default     = "wordpress"
}
variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
}
variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}
variable "db_allocated_storage" {
  description = "RDS storage (GiB)"
  type        = number
  default     = 20
}
variable "db_multi_az" {
  type    = bool
  default = false
}
variable "db_storage_type" {
  type    = string
  default = "gp3"
}
variable "db_backup_retention" {
  type    = number
  default = 0
}
variable "db_skip_final_snapshot" {
  type    = bool
  default = true
}
variable "db_final_snapshot_id" {
  type    = string
  default = "my-final-snapshot"
}

#Docker Compose
variable "compose_arch" {
  description = "Docker Compose binary arch"
  type        = string
  default     = "linux-x86_64"
}

# WordPress
variable "wp_site_title" {
  description = "WordPress site title"
  type        = string
  default     = "My Terraform WordPress Project"
}
variable "wp_admin_user" {
  description = "WordPress admin username"
  type        = string
  default     = "admin"
}
variable "wp_admin_password" {
  description = "WordPress admin password"
  type        = string
  sensitive   = true
}
variable "wp_admin_email" {
  description = "WordPress admin email"
  type        = string
}

# Naming / tagging
variable "name_prefix" {
  description = "Prefix for Name tags on all resources"
  type        = string
  default     = "wp"
}
variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

# VPC & subnets
variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.100.0.0/16"
}
variable "azs" {
  description = "Ordered list of AZs to use"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
}
variable "public_subnet_cidrs" {
  description = "Map of AZ to CIDR for public subnets"
  type        = map(string)
  default = {
    "eu-west-2a" = "10.100.1.0/24"
    "eu-west-2b" = "10.100.2.0/24"
  }
}
variable "private_subnet_cidrs" {
  description = "Map of AZ to CIDR for private subnets"
  type        = map(string)
  default = {
    "eu-west-2a" = "10.100.3.0/24"
    "eu-west-2b" = "10.100.4.0/24"
  }
}

# SG & ports
variable "ssh_port" {
  type    = number
  default = 22
}
variable "http_port" {
  type    = number
  default = 80
}
variable "allowed_ssh_cidrs" {
  description = "CIDRs allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
variable "allowed_http_cidrs" {
  description = "CIDRs allowed to HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
variable "any_ipv4_cidr" {
  description = "Shortcut for 0.0.0.0/0"
  type        = string
  default     = "0.0.0.0/0"
}
variable "egress_ipv4_cidrs" {
  description = "IPv4 egress CIDRs"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
variable "egress_ipv6_cidrs" {
  description = "IPv6 egress CIDRs"
  type        = list(string)
  default     = ["::/0"]
}

/*

  # Networking
  # variable "vpc_cidr" {
  #   description = "VPC CIDR"
  #   type        = string
  #   default     = "10.100.0.0/16"
  # }
  # variable "azs" {
  #   description = "Availability Zones to use (index 0 hosts NAT + EC2)"
  #   type        = list(string)
  #   default     = ["eu-west-2a", "eu-west-2b"]
  # }
  # variable "public_subnet_cidrs" {
  #   description = "Map AZ -> public subnet CIDR"
  #   type        = map(string)
  #   default = {
  #     "eu-west-2a" = "10.100.1.0/24"
  #     "eu-west-2b" = "10.100.2.0/24"
  #   }
  # }
  # variable "private_subnet_cidrs" {
  #   description = "Map AZ -> private subnet CIDR"
  #   type        = map(string)
  #   default = {
  #     "eu-west-2a" = "10.100.3.0/24"
  #     "eu-west-2b" = "10.100.4.0/24"
  #   }
  # }


  # Region
    variable "region" {
      type    = string
      default = "eu-west-2"
    }
    variable "ami_id" {
      type        = string
      description = "t3.micro in eu-west-2"
      default     = "ami-0971f6afca696ace6"
    }
    variable "instance_type" {
      type    = string
      default = "t3.micro"
    }
    variable "instance_name" {
      type    = string
      default = "wp-instance"
    }
    variable "key_name" {
      description = "Key pair to use in AWS eu-west-2"
      type        = string
    }
    variable "azs" {
      type    = list(string)
      default = ["eu-west-2a", "eu-west-2b"]
    }
    # Map AZ -> CIDR for public/private subnets
    variable "public_subnet_cidrs" {
      type = map(string)
      default = {
        "eu-west-2a" = "10.100.1.0/24"
        "eu-west-2b" = "10.100.2.0/24"
      }
    }
    variable "private_subnet_cidrs" {
      type = map(string)
      default = {
        "eu-west-2a" = "10.100.3.0/24"
        "eu-west-2b" = "10.100.4.0/24"
      }}

  # CIDR
  # variable "allowed_ssh_cidrs" {
  #   type    = list(string)
  #   default = ["0.0.0.0/0"]
  # }
  # variable "allowed_http_cidrs" {
  #   type    = list(string)
  #   default = ["0.0.0.0/0"]
  #
  # }

  */
