# WordPress on AWS with Terraform

Automated deployment of WordPress using Terraform, Docker, Amazon RDS MySQL, and EC2.

## Architecture

### High-Level Overview

```
                    Internet
                       ↕
                 [Internet Gateway]
                       ↕
        ┌──────────────────────────────────────┐
        │            VPC (10.100.0.0/16)       │
        │                                      │
        │  ┌─────────────────────────────────┐ │
        │  │   Public Subnets (Multi-AZ)     │ │
        │  │   10.100.1.0/24, 10.100.2.0/24  │ │
        │  │                                 │ │
        │  │  ┌──────────┐    ┌───────────┐  │ │
        │  │  │   EC2    │    │    NAT    │  │ │
        │  │  │WordPress │    │  Gateway  │  │ │
        │  │  │ (Docker) │    │           │  │ │
        │  │  └────┬─────┘    └─────┬─────┘  │ │
        │  └───────┼────────────────┼────────┘ │
        │          │                │          │
        │          ↓                ↓          │
        │  ┌─────────────────────────────────┐ │
        │  │   Private Subnets (Multi-AZ)    │ │
        │  │   10.100.3.0/24, 10.100.4.0/24  │ │
        │  │                                 │ │
        │  │        ┌──────────────┐         │ │
        │  │        │  RDS MySQL   │         │ │
        │  │        │  Multi-AZ    │         │ │
        │  │        └──────────────┘         │ │
        │  └─────────────────────────────────┘ │
        │                                      │
        └──────────────────────────────────────┘

     External Services:
     - AWS Secrets Manager (database credentials)
     - Route Tables (traffic routing)
     - Security Groups (firewall rules)
```

### Network Architecture Details

**Public Subnet (10.100.1.0/24, 10.100.2.0/24):**

- Direct route to Internet Gateway (0.0.0.0/0 → IGW)
- Hosts: EC2 instances, NAT Gateway
- Auto-assigns public IP addresses
- Accessible from internet (with security group rules)

**Private Subnet (10.100.3.0/24, 10.100.4.0/24):**

- Route to internet via NAT Gateway (0.0.0.0/0 → NAT)
- Hosts: RDS database
- No public IP addresses
- Cannot receive inbound connections from internet
- Can initiate outbound connections (for patches, updates)

**Route Tables:**

```
Public Route Table:
  10.100.0.0/16 → local (VPC internal)
  0.0.0.0/0     → igw-xxxxx (Internet Gateway)

Private Route Table:
  10.100.0.0/16 → local (VPC internal)
  0.0.0.0/0     → nat-xxxxx (NAT Gateway)
```

### Security Architecture

**Defense in Depth:**

```
Layer 1: Network (VPC)
├─ Public/Private subnet isolation
└─ NAT Gateway for controlled outbound access

Layer 2: Security Groups (Stateful Firewall)
├─ Web SG: SSH (your IP), HTTP (world)
└─ RDS SG: MySQL (Web SG only)

Layer 3: IAM (Authentication)
├─ EC2 instance role
└─ Secrets Manager access policy

Layer 4: Secrets Manager (Credential Storage)
├─ Encrypted at rest (KMS)
└─ Access logging (CloudTrail)

Layer 5: Application (WordPress)
└─ WordPress admin authentication
```

**Traffic Flow Examples:**

_User accessing WordPress:_

```
Internet → IGW → Public Subnet → EC2:80 → WordPress Container
```

_WordPress querying database:_

```
EC2 → Private Subnet → RDS:3306 (within VPC, no internet)
```

_EC2 downloading packages:_

```
EC2 → NAT Gateway → IGW → Internet
```

_RDS downloading patches:_

```
RDS → NAT Gateway → IGW → Internet (outbound only)
```

### Components

| Component            | Purpose                        | Location       | Cost/Month          |
| -------------------- | ------------------------------ | -------------- | ------------------- |
| **VPC**              | Network isolation              | Regional       | Free                |
| **Internet Gateway** | Public subnet internet access  | VPC            | Free                |
| **NAT Gateway**      | Private subnet outbound access | Public Subnet  | ~$32                |
| **EC2 t3.micro**     | WordPress application server   | Public Subnet  | ~$7.50              |
| **RDS db.t3.micro**  | MySQL database                 | Private Subnet | ~$12                |
| **Elastic IP**       | Static IP for NAT              | NAT Gateway    | $0 (while attached) |
| **Secrets Manager**  | Database credentials           | Regional       | $0.40               |
| **Security Groups**  | Virtual firewall               | VPC            | Free                |
| **Route Tables**     | Traffic routing                | VPC            | Free                |

**Total: ~$52/month**

## Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.6.0
- An EC2 key pair created in AWS (or let Terraform create one)
- S3 bucket for Terraform state (optional)

## Project Structure

```
wordpress-tf/
├── envs/
│   └── dev/
│       ├── backend.tf                # Remote state configuration
│       ├── main.tf                   # Module orchestration
│       ├── providers.tf              # AWS provider config
│       ├── variables.tf              # Variable definitions
│       ├── outputs.tf                # Output definitions
│       ├── terraform.tfvars          # Variable values (gitignored)
│       └── terraform.tfvars.example  # Template for variables
├── modules/
│   ├── vpc/                          # Network infrastructure
│   ├── security_groups/              # Firewall rules
│   ├── rds_mysql/                    # Database
│   └── ec2_wordpress/                # Compute & WordPress
│       └── user_data/
│           └── bootstrap.sh          # EC2 initialization script
├── docs/
│   ├── images/                       # Screenshots
│   └── notes.md                      # Technical notes
├── .gitignore
├── .terraform-version
└── README.md
```

## Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/tomakady/ec2-wordpress
cd wordpress-tf/envs/dev

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

### 2. Update Variables

Edit `terraform.tfvars`:

```hcl
region   = "eu-west-2"
ami_id   = "ami-0971f6afca696ace6"  # Amazon Linux 2023
key_name = "your-key-name"

# Restrict SSH access to your IP
allowed_ssh_cidrs  = ["YOUR_IP/32"]
allowed_http_cidrs = ["0.0.0.0/0"]

# WordPress admin credentials
wp_admin_user     = "admin"
wp_admin_password = "YourSecurePassword123!"
wp_admin_email    = "your-email@example.com"

# Database secret name (must be unique)
db_secret_name = "wp/rds-master-v1"
```

### 3. Deploy

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply

# Note the outputs (WordPress URL, SSH command, etc.)
```

### 4. Access WordPress

After 3-5 minutes (wait for bootstrap to complete):

```
http://<your-ec2-public-ip>/
```

Complete the WordPress installation wizard.

## Monitoring Deployment

Check bootstrap progress:

```bash
# SSH into instance
ssh -i your-key.pem ec2-user@<your-ec2-public-ip>

# Watch bootstrap log
sudo tail -f /var/log/bootstrap.log

# Check Docker container status
docker ps

# View WordPress logs
docker logs <container-id>
```

## What Gets Created

| Resource        | Description             | Cost (approx)           |
| --------------- | ----------------------- | ----------------------- |
| VPC             | Virtual network         | Free                    |
| EC2 t3.micro    | WordPress server        | $0.0104/hour            |
| RDS db.t3.micro | MySQL database          | $0.017/hour             |
| NAT Gateway     | Private subnet internet | $0.045/hour             |
| Elastic IP      | Static IP for NAT       | $0.005/hour (if unused) |
| Secrets Manager | DB credentials          | $0.40/month             |
| **Total**       |                         | **~$45-50/month**       |

## Cleanup

To destroy all resources:

```bash
cd envs/dev
terraform destroy
```

**Note:** If you get errors about Secrets Manager, manually delete secrets:

```bash
aws secretsmanager delete-secret \
  --secret-id wp/rds-master-v1 \
  --force-delete-without-recovery \
  --region eu-west-2
```

## Security Notes

**Default Configuration:**

- SSH access: Restricted to specified IPs
- HTTP access: Open to internet (0.0.0.0/0)
- RDS: Private subnet, only accessible from EC2
- Database credentials: Stored in AWS Secrets Manager

**Production Recommendations:**

1. Use HTTPS with ACM certificate and CloudFront
2. Enable RDS encryption and multi-AZ
3. Use Auto Scaling Group with ALB
4. Enable CloudWatch monitoring
5. Regular automated backups
6. Use AWS Systems Manager instead of SSH

## Troubleshooting

### WordPress not accessible

```bash
# Check security group allows port 80
aws ec2 describe-security-groups --group-ids <sg-id>

# SSH and check Docker
ssh -i key.pem ec2-user@<ip>
docker ps
docker logs <container-id>
```

### Database connection errors

```bash
# Check RDS is reachable from EC2
nc -zv <rds-endpoint> 3306

# Verify credentials
docker exec <container-id> env | grep WORDPRESS_DB
```

### Bootstrap script failed

```bash
# Check logs
sudo cat /var/log/bootstrap.log

# Common issues:
# - RDS took too long to start (wait and reboot EC2)
# - IAM permissions missing (check role can read secrets)
# - Docker Compose download failed (check internet connectivity)
```

## Customization

### Change WordPress version

Edit `modules/ec2_wordpress/user_data/bootstrap.sh`:

```bash
image: wordpress:6.7-php8.3-apache  # Update version here
```

### Add plugins via Docker

Mount a plugins directory:

```yaml
volumes:
  - wp_content:/var/www/html/wp-content
  - ./plugins:/var/www/html/wp-content/plugins
```

### Use different database engine

Modify `modules/rds_mysql/variables.tf`:

```hcl
variable "db_engine" {
  default = "mariadb"  # or "postgres" (requires code changes)
}
```

## Contributing

1. Create feature branch
2. Make changes
3. Test with `terraform plan`
4. Submit pull request

👤 Author: Tomasz Kadyszewski
📍 UK | DevOps Engineer
