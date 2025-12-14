###############################################
# EC2 Module Outputs
###############################################

# The public IPv4 address of the EC2 instance.
# This is used to access the Flask web application from the browser.
output "ec2_public_ip" {
  description = "Public IP address of the EC2 web server"
  value       = aws_instance.web.public_ip
}

# The public DNS hostname of the EC2 instance.
# Equivalent to the Public IP but helpful for DNS-based access.
output "ec2_public_dns" {
  description = "Public DNS name of the EC2 web server"
  value       = aws_instance.web.public_dns
}

# Security Group ID associated with the EC2 instance.
# This is needed by other modules (e.g., RDS) to allow inbound connections.
output "ec2_sg_id" {
  description = "Security Group ID of the EC2 instance"
  value       = aws_security_group.ec2_sg.id
}
