###############################################
# General Project Configuration
###############################################

# Prefix applied to all resources created by this module.
# Ensures consistent naming across VPC, subnets, route tables, etc.
variable "project" {
  type        = string
  description = "Project name prefix"
}

###############################################
# VPC & Subnet CIDR Configuration
###############################################

# CIDR block of the main VPC that defines the overall network boundary.
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

# CIDR range for the public subnet where internet-facing resources
# (e.g., EC2 web server) will be deployed.
variable "public_subnet_cidr" {
  type        = string
  description = "Public subnet CIDR"
}

# CIDR range for the first private subnet (placed in AZ1).
# Used by internal-only resources such as RDS.
variable "private_subnet_cidr_1" {
  type        = string
  description = "Private subnet 1 CIDR (AZ1)"
}

# CIDR range for the second private subnet (placed in AZ2).
# Required by AWS RDS subnet groups, which must span ≥2 AZs.
variable "private_subnet_cidr_2" {
  type        = string
  description = "Private subnet 2 CIDR (AZ2)"
}

###############################################
# Availability Zones
###############################################

# List of availability zones used for subnet placement.
# Must contain at least two AZs because RDS requires
# multi-subnet architecture even for single-AZ deployments.
variable "azs" {
  type        = list(string)
  description = "List of availability zones (must have at least 2)"
}
