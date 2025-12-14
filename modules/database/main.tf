###############################################
# RDS Security Group
###############################################
# This security group allows ONLY the EC2 instance (by SG ID)
# to connect to the RDS MySQL database on port 3306.
# No other inbound access is allowed → secure by design.
resource "aws_security_group" "db_sg" {
  name        = "${var.project}-rds-sg"
  description = "Allow EC2 web server to access MySQL"
  vpc_id      = var.vpc_id

  # Allow MySQL traffic only from the EC2 instance SG
  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.ec2_sg_id]
  }

  # Allow all outbound traffic (required for DB engine updates, patches, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-db-sg"
  }
}

###############################################
# DB Subnet Group (Required for RDS)
###############################################
# RDS requires at least **two private subnets** across different AZs.
# The DB Subnet Group tells AWS where the RDS instance is allowed to live.
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project}-db-subnet-group"
  }
}

###############################################
# RDS MySQL Instance (Single-AZ)
###############################################
# This creates a secure private MySQL database instance.
# - Not publicly accessible
# - Running in private subnets
# - Connected only to EC2 via SG rules
resource "aws_db_instance" "mysql" {
  identifier              = "${var.project}-mysql-db"

  # Database engine configuration
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class

  allocated_storage       = 20  # small footprint for MVP

  # Credentials passed via module inputs
  username                = var.db_username
  password                = var.db_password

  # Networking: use the private subnet group + SG
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]

  # Security & deployment options
  publicly_accessible     = false   # stays private
  multi_az                = false   # Single-AZ for MVP (cheaper)
  skip_final_snapshot     = true    # NO snapshot when destroyed (dev mode)

  port                    = var.db_port
}


