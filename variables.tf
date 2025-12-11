########################################
# PROJECT VARIABLES
# Global settings used across all modules
########################################

# Project-wide prefix applied to all named resources
variable "project" {
  description = "Project name prefix applied to all resources"
  type        = string
  default     = "mvp"
}

# AWS region where the entire infrastructure is deployed
variable "region" {
  description = "AWS region where the infrastructure is deployed"
  type        = string
  default     = "eu-central-1"
}

########################################
# VPC VARIABLES
# Network configuration for the VPC and subnets
########################################

# CIDR range defining the VPC network boundary
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Availability Zones used to distribute the subnets
variable "azs" {
  description = "Availability Zones used for public and private subnets"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

# CIDR block used for the single public subnet
variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# CIDR ranges for the two private subnets used by RDS
variable "private_subnets" {
  description = "CIDR blocks for the private subnets (used by RDS)"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
}

########################################
# EC2 VARIABLES
########################################
# AMI used to launch the EC2 instance (Ubuntu 22.04 in eu-central-1)
variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI for eu-central-1"
  type        = string
  default     = "ami-0e2108df824ee2a7b"
}

# Instance size for the EC2 web server
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

# Restricts SSH access to your own public IP for security
variable "my_ip" {
  description = "Your public IP for SSH access (e.g., 1.2.3.4/32)"
  type        = string
  default     = "x.x.x.x/32"
}

########################################
# RDS VARIABLES
########################################

# Master username used to authenticate into the MySQL database
variable "db_username" {
  description = "Master username for the RDS MySQL instance"
  type        = string
  default     = "admin"
}

# Master password for the RDS instance (sensitive)
variable "db_password" {
  description = "Master password for the RDS MySQL instance"
  type        = string
  sensitive   = true
  default     = "Admin123456!"
}

# Instance class defining compute/memory for the RDS instance
variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

# Database engine type (MySQL, PostgreSQL, etc.)
variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
}

# Exact version of the MySQL engine
variable "db_engine_version" {
  description = "Full engine version"
  type        = string
  default     = "8.0.44"
}

# Parameter group family used for MySQL configurations
variable "family" {
  description = "Parameter group family"
  type        = string
  default     = "mysql8.0"
}

# Major engine version required for option group compatibility
variable "major_engine_version" {
  description = "Major engine version for RDS option group"
  type        = string
  default     = "8.0"
}

# Port number on which MySQL listens
variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}
