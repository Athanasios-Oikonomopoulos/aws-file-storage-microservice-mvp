###############################################
# RDS Outputs
###############################################

# The DNS endpoint of the RDS MySQL instance.
# This value is required by the EC2 instance so the Flask app
# can connect to the database during startup.
output "db_endpoint" {
  value       = aws_db_instance.mysql.address
  description = "DNS endpoint of the RDS MySQL instance"
}

# The port on which the MySQL engine is listening (default: 3306).
# Also passed to EC2 if needed.
output "db_port" {
  value       = aws_db_instance.mysql.port
  description = "Port number for the RDS MySQL instance"
}

# The security group ID assigned to the RDS instance.
# Used by other modules (e.g., EC2) if additional rules are required.
output "db_sg_id" {
  value       = aws_security_group.db_sg.id
  description = "Security Group ID associated with the RDS instance"
}
