variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "S3 bucket for backups"
  default     = "terraform-dr-backup-bucket"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-01e3c4a339a264cc9"  # Change this to a valid AMI
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_name" {
  description = "Key pair name for EC2 instance"
  default     = "Key-pair"
}

