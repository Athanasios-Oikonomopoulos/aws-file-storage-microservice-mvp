###############################################
# General Project Metadata
###############################################

# Prefix used for naming and tagging RDS resources.
variable "project" {
  type = string
}

###############################################
# Networking Inputs
###############################################

# Two private subnets across two Availability Zones.
# AWS requires at least two subnets for an RDS subnet group,
# even when the DB instance itself is Single-AZ.
variable "private_subnet_ids" {
  type        = list(string)
  description = "Two private subnets across two AZs"
}

# The VPC ID where the RDS instance will be deployed.
variable "vpc_id" {
  type = string
}

# Security Group ID of the EC2 instance, used to allow inbound MySQL traffic.
variable "ec2_sg_id" {
  type        = string
  description = "Security group ID of the EC2 instance"
}

###############################################
# Database Authentication
###############################################

# Username for the RDS MySQL instance.
variable "db_username" {
  type = string
}

# Password for the MySQL RDS instance.
# Marked as sensitive so it does not appear in CLI logs or state file outputs.
variable "db_password" {
  type      = string
  sensitive = true
}

###############################################
# DB Engine Configuration
###############################################

# The instance class (e.g., db.t3.micro). Passed in from the environment.
variable "db_instance_class" {
  type = string
}

# Database engine (default: MySQL)
variable "db_engine" {
  type    = string
  default = "mysql"
}

# MySQL version — using an up-to-date 8.x release.
variable "db_engine_version" {
  type    = string
  default = "8.0.44"
}

# Port on which MySQL listens.
variable "db_port" {
  type    = number
  default = 3306
}
