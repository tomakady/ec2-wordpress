# WordPress on AWS with Terraform

Automated deployment of WordPress using Terraform, Docker, Amazon RDS MySQL, and EC2.

This project demonstrates the deployment of a highly available WordPress application on AWS using Terraform and modular Infrastructure as Code practices. It includes networking, compute, database and secure state management.

## Project Structure

```
wordpress-tf/
├── envs/
│   └── dev/
│       ├── backend.tf              # Remote state configuration
│       ├── main.tf                 # Module orchestration
│       ├── providers.tf            # AWS provider config
│       ├── variables.tf            # Variable definitions
│       ├── outputs.tf              # Output definitions
│       ├── terraform.tfvars        # Variable values (gitignored)
│       └── terraform.tfvars.example # Template for variables
├── modules/
│   ├── vpc/                        # Network infrastructure
│   ├── security_groups/            # Firewall rules
│   ├── rds_mysql/                  # Database
│   └── ec2_wordpress/              # Compute & WordPress
│       └── user_data/
│           └── bootstrap.sh        # EC2 initialization script
├── docs/
│   ├── images/                     # Screenshots
│   └── notes.md                    # Technical notes
├── .gitignore
├── .terraform-version
└── README.md
```

---

## Goals

- Deploy a multi-AZ WordPress environment with Terraform
- Use modular design (VPC, EC2, RDS, ALB separated)
- Secure infrastructure with least privilege security groups
- Automate WordPress installation via cloud-init

---

## Tech Stack

- Terraform - Infrastructure as Code
- AWS - VPC, EC2, RDS
- WordPress - Application layer
- MySQL RDS - Database backend
- Cloud-Init - EC2 bootstrapping

---

## Prerequisites

- AWS account with permissions (VPC, EC2, RDS, S3)
- Terraform installed
- AWS CLI configured (aws configure)
- Existing S3 bucket with versioning and state locking enabled (update backend.tf accordingly)

---

## Deployment Steps

# 1. Clone repository

git clone https://github.com/tomakady/ec2-wordpress.git
cd DevOps-Learning-Terraform/envs/dev

# 2. Copy and edit variables

mv terraform.tfvars.example terraform.tfvars

# Update values:

    •	VPC + Subnets - CIDR blocks for VPC, public, and private subnets
    •	SSH Access - my_ip_cidr (your public IP/32) + key_name (your EC2 keypair)
    •	EC2 (WordPress app) - ami_type, instance_type, optional acm_cert_arn
    •	RDS Database - db_user, db_passwd, db_name

# 3. Initialize with remote backend or locally

terraform init

# 4. Preview resources

terraform plan

# 5. Apply changes

terraform apply --auto-approve

# 6. Access WordPress

# Once complete, Terraform will output the ALB DNS endpoint.

# Open it in your browser to access WordPress setup.

# 7. Cleanup (destroy resources when done)

terraform destroy --auto-approve

---

👤 Author: Tomasz Kadyszewski
📍 UK | DevOps Engineer
