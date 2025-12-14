###############################################################
# EC2 OUTPUTS
###############################################################

# Public IP of the EC2 instance
output "ec2_public_ip" {
  description = "Public IP address of the EC2 web server"
  value       = module.compute.ec2_public_ip
}

# Public DNS hostname of the EC2 instance
output "ec2_public_dns" {
  description = "Public DNS name of the EC2 web server"
  value       = module.compute.ec2_public_dns
}

###############################################################
# S3 OUTPUTS
###############################################################

# The name of the S3 bucket used for storing uploaded files
output "s3_bucket_name" {
  description = "S3 bucket name used by the Flask application"
  value       = module.storage.bucket_name
}

###############################################################
# RDS OUTPUTS
###############################################################

# Connection endpoint for the MySQL RDS instance
output "rds_endpoint" {
  description = "RDS MySQL database endpoint address"
  value       = module.database.db_endpoint
}
