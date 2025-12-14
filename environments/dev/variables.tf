########################################
# GLOBAL PROJECT SETTINGS
########################################

# Prefix applied to most AWS resource names for consistency
variable "project" {
  description = "Project name prefix"
  type        = string
  default     = "mvp"
}

# AWS region used for all resources
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

########################################
# NETWORK VARIABLES
########################################

# Main VPC CIDR block
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Public subnet for EC2 web server
variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# First private subnet (AZ1) for RDS subnet group
variable "private_subnet_cidr_1" {
  description = "CIDR block for private subnet (AZ1)"
  type        = string
  default     = "10.0.2.0/24"
}

# Second private subnet (AZ2) for RDS subnet group
variable "private_subnet_cidr_2" {
  description = "CIDR block for private subnet (AZ2)"
  type        = string
  default     = "10.0.3.0/24"
}

# Availability Zones used for high-availability placement
variable "azs" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

########################################
# COMPUTE VARIABLES (EC2)
########################################

# AMI used to launch the EC2 instance
variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-0e2108df824ee2a7b"
}

# EC2 instance size (defaults to free-tier eligible)
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

# Restrict SSH access to your own public IP
variable "my_ip" {
  description = "Your public IP for SSH"
  type        = string
  default     = "x.x.x.x/32"
}

# Required EC2 key pair for SSH access
variable "key_name" {
  description = "Key pair name for EC2 instance"
  type        = string
}

########################################
# DATABASE VARIABLES (RDS)
########################################

# RDS master username
variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

# RDS master password (kept sensitive)
variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  default     = "Admin123456!"
}

# RDS compute class (free-tier compatible)
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}
