########################################
# VPC Output
########################################
# Exposes the VPC ID so that other modules (compute, database, etc.)
# can attach resources inside the same network boundary.
output "vpc_id" {
  value = aws_vpc.this.id
}

########################################
# Public Subnet Output
########################################
# This subnet is used by the EC2 compute module to place the web server
# in a subnet with internet access through the Internet Gateway.
output "public_subnet_id" {
  value = aws_subnet.public.id
}

########################################
# Private Subnets Output
########################################
# RDS requires **at least two subnets in different Availability Zones**
# to create a DB subnet group.
# We output both and pass them to the database module.
output "private_subnet_ids" {
  value = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]
}
