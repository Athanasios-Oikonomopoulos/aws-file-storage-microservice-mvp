###############################################
# RANDOM STRING SUFFIX
###############################################
# S3 bucket names must be globally unique across all AWS accounts.
# This resource generates a 6-digit random string and appends it to
# the bucket name to guarantee uniqueness.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}

###############################################
# S3 BUCKET (Private Application Storage)
###############################################
# Main S3 bucket used by the Flask microservice for file uploads
# and downloads. The name includes the random suffix to avoid
# naming conflicts in AWS global namespace.
resource "aws_s3_bucket" "this" {
  bucket = "${var.project}-storage-bucket-${random_string.suffix.id}"

  tags = {
    Project = var.project
    Purpose = "AppStorage"
  }
}

###############################################
# BLOCK PUBLIC ACCESS (Security Best Practice)
###############################################
# Prevents *any* form of public access to the bucket.
# This protects files stored by the microservice and ensures
# that no object or bucket policies can make it public.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

###############################################
# BUCKET OWNERSHIP & ACL CONTROLS
###############################################
# Enforces the modern AWS S3 standard: ACLs disabled and the bucket
# owner has full control. Prevents cross-account ACL issues and
# guarantees consistency.
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

###############################################
# SERVER-SIDE ENCRYPTION (SSE)
###############################################
# Ensures all objects uploaded to the bucket are automatically
# encrypted using AES-256. This is a core security practice and
# prevents accidental storage of unencrypted data.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

###############################################
# VERSIONING
###############################################
# Enables versioning so that overwritten or deleted files can be
# recovered. Useful for debugging, auditing change history, and
# preventing accidental data loss.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}
