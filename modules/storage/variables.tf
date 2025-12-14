##########################################################
# PROJECT IDENTIFIER
##########################################################

# Project name prefix used when constructing the S3 bucket name.
# Ensures consistent naming across all Terraform-managed resources.
variable "project" {
  type        = string
  description = "Project name prefix used for S3 bucket naming"
}
