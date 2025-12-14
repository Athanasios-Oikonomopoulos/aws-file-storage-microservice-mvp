###############################################################
# TERRAFORM + PROVIDERS CONFIGURATION
###############################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source = "hashicorp/random"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# AWS Provider configuration (region injected via variables)
provider "aws" {
  region = var.region
}

###############################################################
# NETWORK MODULE
# - Creates VPC, public + private subnets, route tables, IGW
# - Outputs: vpc_id, public_subnet_id, private_subnet_ids
###############################################################
module "network" {
  source = "../../modules/network"

  project               = var.project
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidr    = var.public_subnet_cidr
  private_subnet_cidr_1 = var.private_subnet_cidr_1
  private_subnet_cidr_2 = var.private_subnet_cidr_2
  azs                   = var.azs
}

###############################################################
# STORAGE MODULE (S3)
# - Creates encrypted, versioned, private S3 bucket
# - Outputs: bucket_name, bucket_arn, bucket_domain_name
###############################################################
module "storage" {
  source  = "../../modules/storage"
  project = var.project
}

###############################################################
# COMPUTE MODULE (EC2)
# - Launches EC2 instance
# - Attaches IAM role, uploads user_data, exposes public IP
# - Injects S3 + RDS connection values into startup script
###############################################################
module "compute" {
  source = "../../modules/compute"

  # General config
  project       = var.project
  ami_id        = var.ami_id
  instance_type = var.instance_type
  my_ip         = var.my_ip
  key_name      = var.key_name

  # Network integration
  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_id

  # Cross-module connections
  bucket_name = module.storage.bucket_name
  db_endpoint = module.database.db_endpoint

  # Database credentials passed via user_data
  db_username = var.db_username
  db_password = var.db_password
}

###############################################################
# DATABASE MODULE (RDS MySQL)
# - Creates security group, subnet group, and RDS instance
# - Restricts MySQL access to EC2 SG only
###############################################################
module "database" {
  source = "../../modules/database"

  # General project settings
  project = var.project

  # Networking requirements
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  # Allow RDS access from the EC2 instance
  ec2_sg_id = module.compute.ec2_sg_id

  # Database engine/credentials
  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = var.db_instance_class
}
