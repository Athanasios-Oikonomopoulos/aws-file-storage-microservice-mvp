###############################################
# S3 BUCKET OUTPUTS
###############################################

# The final name of the S3 bucket, including the random suffix.
# Used by the compute module (EC2) to upload and download files.
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.this.bucket
}

# The full Amazon Resource Name (ARN) of the bucket.
# Useful for IAM policies, permissions, or cross-service integration.
output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.this.arn
}

# The bucket’s domain-style endpoint, e.g., bucket-name.s3.amazonaws.com.
# This is sometimes used in SDKs or direct HTTP interactions.
output "bucket_domain_name" {
  description = "Bucket domain name"
  value       = aws_s3_bucket.this.bucket_domain_name
}
