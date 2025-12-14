###############################################
# General Project Variables
###############################################

# Name of the project used for tagging AWS resources.
variable "project" {
  type = string
}

###############################################
# Networking Variables
###############################################

# The ID of the VPC into which the EC2 instance will be deployed.
variable "vpc_id" {
  type = string
}

# The public subnet where the EC2 web server will be launched.
variable "public_subnet_id" {
  type = string
}

###############################################
# EC2 Instance Configuration
###############################################

# AMI ID for the EC2 instance. Typically an Ubuntu, Amazon Linux, etc.
variable "ami_id" {
  type = string
}

# EC2 instance type. Defaults to t2.micro for free-tier compatibility.
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

# Your public IP address, used to restrict SSH access via the EC2 Security Group.
variable "my_ip" {
  type        = string
  description = "Your public IP for SSH"
}

# Name of the EC2 key pair for SSH access.
variable "key_name" {
  type        = string
  description = "EC2 key pair name for SSH"
}

###############################################
# Database (RDS) Configuration
###############################################

# Username for MySQL RDS instance.
variable "db_username" {
  type = string
}

# Password for MySQL RDS instance.
# Marked as sensitive so Terraform hides the value in logs/state.
variable "db_password" {
  type      = string
  sensitive = true
}

# The RDS endpoint created by the database module.
# Injected into the EC2 user_data so the Flask app can connect.
variable "db_endpoint" {
  type = string
}

###############################################
# Storage (S3) Configuration
###############################################

# Name of the S3 bucket used by the Flask upload/download microservice.
variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket used by the app"
}
