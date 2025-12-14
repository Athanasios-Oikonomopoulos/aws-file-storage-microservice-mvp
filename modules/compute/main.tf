########################################
# EC2 Security Group
########################################
# This security group controls inbound/outbound traffic for the EC2 web server.
# - Allows HTTP (80) from anywhere so the web app is publicly reachable.
# - Allows SSH (22) ONLY from your public IP for secure administration.
# - Allows all outbound traffic so the instance can reach S3, RDS, etc.
resource "aws_security_group" "ec2_sg" {
  vpc_id = var.vpc_id
  name   = "${var.project}-ec2-sg"

  # Public web access
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # Allow all clients to reach the Flask app
  }

  # Restrict SSH to your personal IP
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]     # Only YOU can SSH into the EC2 instance
  }

  # Allow EC2 to talk to external services (S3, RDS, updates, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-ec2-sg"
  }
}

########################################
# IAM Role for EC2
########################################
# This IAM role allows the EC2 instance to assume AWS permissions.
# The attached policies allow:
# - Full access to S3 (for uploads/downloads)
# - CloudWatch logging (useful for debugging/monitoring)
resource "aws_iam_role" "ec2_role" {
  name = "${var.project}-ec2-role"

  # Trust relationship: allows EC2 to assume this IAM role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach Amazon S3 Full Access so Flask can upload/download files.
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Allows EC2 to publish system/app logs to CloudWatch.
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Creates an IAM Instance Profile that EC2 uses to actually consume the role.
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

########################################
# EC2 Instance
########################################
# This launches the web server that hosts your Flask application.
# It receives:
# - VPC and subnet placement
# - Security group
# - IAM role (via instance profile)
# - SSH key pair
# - User data template that injects S3 + RDS connection values and auto-deploys the app.
resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  # Key pair used to SSH into the server.
  key_name = var.key_name

  # Inject dynamic values into startup.sh before it runs on the instance.
  user_data = templatefile("${path.module}/startup.sh", {
    bucket_name   = var.bucket_name     # S3 bucket for file uploads
    db_endpoint   = var.db_endpoint     # RDS endpoint for MySQL logging
    db_username   = var.db_username     # MySQL username
    db_password   = var.db_password     # MySQL password
  })

  tags = {
    Name = "${var.project}-web"
    Role = "WebServer"
  }
}
