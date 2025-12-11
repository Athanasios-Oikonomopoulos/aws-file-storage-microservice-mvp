########################################
# VPC MODULE
# Creates the main network boundary:
# - VPC
# - Public + private subnets
# - Routing tables and IGW
########################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.5.1"

  name = "${var.project}-vpc"
  cidr = var.vpc_cidr

  # Availability Zones used by the VPC
  azs = var.azs

  # Subnet configuration
  public_subnets  = [var.public_subnet_cidr]
  private_subnets = var.private_subnets

  # VPC networking features
  map_public_ip_on_launch = true
  enable_nat_gateway      = false
  enable_dns_hostnames    = true
  enable_dns_support      = true

  tags = {
    Project     = var.project
    Environment = "dev"
  }
}

########################################
# EC2 SECURITY GROUP
########################################
# Creates a security group for the EC2 web server.
# Allows HTTP from anywhere and SSH only from my IP.
# Outbound traffic is fully allowed so EC2 can reach RDS, S3, etc.
module "ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.project}-ec2-sg"
  description = "Security group for EC2 web server"
  vpc_id      = module.vpc.vpc_id

  # Inbound rules: public HTTP + restricted SSH
  ingress_with_cidr_blocks = [
    {
      description = "HTTP access"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.my_ip
    }
  ]

  # Outbound rule: allow EC2 to reach the internet and internal services
  egress_with_cidr_blocks = [
    {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

########################################
# IAM ROLE FOR EC2
########################################
# IAM role that EC2 assumes at launch. Grants permissions for S3 access
# and CloudWatch integration.
resource "aws_iam_role" "ec2_role" {
  name = "${var.project}-ec2-role"

  # EC2 is trusted to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Grants EC2 permission to read/write S3 (diagram: EC2 → S3)
resource "aws_iam_role_policy_attachment" "ec2_s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Grants EC2 permission to send logs/metrics to CloudWatch (diagram: EC2 → CloudWatch)
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Required wrapper that attaches the IAM role to the EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}


########################################
# EC2 INSTANCE
########################################
# Deploys the EC2 web server running in the public subnet.
# Uses the EC2 security group, IAM instance profile, and startup script.
module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.1.5"

  # EC2 instance name
  name = "${var.project}-webserver"

  # Base OS image + instance size
  ami           = var.ami_id
  instance_type = var.instance_type

  # Place EC2 in the public subnet with its security group
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.ec2_sg.security_group_id]

  # Ensure the instance gets a public IP for internet/web access
  associate_public_ip_address = true

  # Attach IAM Role (S3 + CloudWatch permissions)
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Automatically deploy web content on boot
  # Pass S3 bucket name into the startup script
  user_data = templatefile("${path.module}/user_data/startup.sh", {
    bucket_name = module.s3.s3_bucket_id
  })

  # Ensures EC2 is replaced when user_data script changes
  user_data_replace_on_change = true

  # Metadata tags
  tags = {
    Role = "WebServer"
  }
}


########################################
# RDS SECURITY GROUP
########################################
# Security group for the RDS MySQL database.
# Allows only the EC2 instance to connect on port 3306 (MySQL).
resource "aws_security_group" "rds_sg" {
  name        = "${var.project}-rds-sg"
  description = "Allow EC2 web server to access MySQL"
  vpc_id      = module.vpc.vpc_id

  # Inbound: EC2 can reach RDS on MySQL port
  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.ec2.security_group_id]
  }

  # Outbound: allow RDS responses and internal communication
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################
# RDS MODULE
########################################
# Deploys a minimal RDS MySQL instance inside the private subnets.
# Not publicly accessible, single-AZ, with automatic subnet group creation.
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.13.1"

  identifier = "${var.project}-mysql-db"

  # Database configuration
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  major_engine_version = var.major_engine_version
  family               = var.family

  instance_class    = var.db_instance_class
  allocated_storage = 20

  username = var.db_username
  password = var.db_password

  # Create subnet group using the two private subnets
  create_db_subnet_group = true
  db_subnet_group_name   = "${var.project}-rds-subnet-group"

  port = var.db_port

  # RDS must span 2 private subnets (across 2 AZs)
  subnet_ids = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1]
  ]

  # Restrict DB access to the RDS SG
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Minimal deployment settings
  publicly_accessible = false
  multi_az            = false
  skip_final_snapshot = true
}

########################################
# RANDOM SUFFIX
########################################
# Generates a random 6-digit string to ensure the S3 bucket name is globally unique.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}

########################################
# S3 BUCKET MODULE 
########################################
# Creates a private S3 bucket used for application storage.
# Bucket name includes a random suffix to avoid global naming conflicts.
module "s3" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.9.0"

  bucket = "${var.project}-storage-bucket-${random_string.suffix.id}"

  # Enforce modern AWS best practice: bucket owner enforced, ACLs disabled
  object_ownership         = "BucketOwnerEnforced"
  control_object_ownership = true
  acl                      = null

  # Enable versioning for data protection
  versioning = {
    enabled = true
  }

  # Encrypt all objects by default using AES256
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Block any form of public access to the bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    Project = var.project
    Purpose = "AppStorage"
  }
}
