# VPC Module
module "vpc" {
  source = "../terraform/modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
  name_prefix          = var.name_prefix
  common_tags          = var.common_tags
}

# Security Groups Module
module "sg" {
  source = "../terraform/modules/sg"

  vpc_id             = module.vpc.vpc_id
  name_prefix        = var.name_prefix
  allowed_ssh_cidrs  = var.allowed_ssh_cidrs
  allowed_http_cidrs = var.allowed_http_cidrs
  common_tags        = var.common_tags
}

# RDS Module
module "rds" {
  source = "../terraform/modules/backend"

  db_identifier          = var.db_identifier
  db_name                = var.db_name
  db_username            = var.db_username
  db_engine              = var.db_engine
  db_engine_version      = var.db_engine_version
  db_instance_class      = var.db_instance_class
  db_allocated_storage   = var.db_allocated_storage
  db_storage_type        = var.db_storage_type
  db_multi_az            = var.db_multi_az
  db_backup_retention    = var.db_backup_retention
  db_skip_final_snapshot = var.db_skip_final_snapshot
  db_final_snapshot_id   = var.db_final_snapshot_id
  db_secret_name         = var.db_secret_name

  private_subnet_ids    = module.vpc.private_subnet_ids
  rds_security_group_id = module.sg.rds_sg_id
  region                = var.region
  name_prefix           = var.name_prefix
  common_tags           = var.common_tags
}

# EC2 Module
module "ec2" {
  source = "../terraform/modules/ec2"

  ami_id             = var.ami_id
  instance_type      = var.instance_type
  key_name           = var.key_name
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.sg.web_sg_id]
  target_group_arn   = module.alb.target_group_arn

  rds_endpoint   = module.rds.rds_endpoint
  db_name        = var.db_name
  db_secret_name = module.rds.db_secret_name
  db_secret_arn  = module.rds.db_secret_arn
  region         = var.region
  name_prefix    = var.name_prefix
  common_tags    = var.common_tags
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.sg.alb_sg_id
  depends_on            = [module.sg]
  name_prefix           = var.name_prefix
}