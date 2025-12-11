########################################
# VPC OUTPUTS
# Exposes key VPC resources for visibility or reuse
########################################

# Returns the unique ID of the created VPC
output "vpc_id" {
  description = "ID of the deployed VPC"
  value       = module.vpc.vpc_id
}

# Returns all public subnet IDs created in the VPC
output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

# Returns all private subnet IDs created in the VPC
output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

########################################
# EC2 OUTPUTS
########################################

# Exposes the public IP so the web server can be accessed
output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.public_ip
}

# Provides the public DNS name of the EC2 instance
output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = module.ec2.public_dns
}



########################################
# RDS OUTPUTS
########################################

# DNS endpoint used by applications to connect to the MySQL database
output "rds_endpoint" {
  description = "RDS MySQL endpoint address"
  value       = module.rds.db_instance_address
}

# Exposes the port that the RDS instance listens on
output "rds_port" {
  description = "RDS MySQL port"
  value       = module.rds.db_instance_port
}


########################################
# S3 OUTPUTS
########################################

# Name of the created S3 bucket
output "s3_bucket_name" {
  description = "Name of the S3 bucket created for the microservice"
  value       = module.s3.s3_bucket_id
}

# ARN of the S3 bucket
output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3.s3_bucket_arn
}

# Helpful domain for uploading/downloading
output "s3_bucket_domain" {
  description = "S3 bucket domain name"
  value       = module.s3.s3_bucket_bucket_domain_name
}
