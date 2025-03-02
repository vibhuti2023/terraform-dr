output "primary_instance_id" {
  description = "The ID of the primary EC2 instance"
  value       = aws_instance.primary_instance.id
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.backup_bucket.bucket
}

