########################################
# VPC (Virtual Private Cloud)
########################################
# Creates an isolated virtual network where all other AWS
# resources (subnets, EC2, RDS, etc.) will be deployed.
# DNS support + hostnames are required for EC2 hostname resolution
# and for RDS endpoint lookups.
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

########################################
# Internet Gateway (IGW)
########################################
# Enables outbound internet access for public subnets.
# Required for EC2 instances that host public web services.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-igw"
  }
}

########################################
# Public Subnet (AZ1)
########################################
# Subnet in the first Availability Zone.
# map_public_ip_on_launch allows EC2 instances to get public IPs
# automatically so they can serve traffic over the internet.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.azs[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-public-subnet"
  }
}

########################################
# Private Subnet 1 (AZ1)
########################################
# First private subnet, isolated from the internet.
# Used by RDS or internal-only services.
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr_1
  availability_zone = var.azs[0]

  tags = {
    Name = "${var.project}-private-subnet-1"
  }
}

########################################
# Private Subnet 2 (AZ2)
########################################
# Second private subnet in another AZ.
# Required by AWS for `aws_db_subnet_group` (minimum 2 AZs).
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr_2
  availability_zone = var.azs[1]

  tags = {
    Name = "${var.project}-private-subnet-2"
  }
}

########################################
# Public Route Table
########################################
# Controls routing for the public subnet.
# Will receive a default route (0.0.0.0/0) to the Internet Gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-public-rt"
  }
}

########################################
# Default Route: Internet Access
########################################
# Adds a route so public subnet instances can reach the internet
# via the Internet Gateway.
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

########################################
# Associate Route Table → Public Subnet
########################################
# Ensures EC2 instances in the public subnet use the public route table.
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
