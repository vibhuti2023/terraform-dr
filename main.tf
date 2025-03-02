terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "terraform-dr-backend-bucket"  # Replace with your unique bucket name
    key            = "terraform.tfstate"
    region         = "us-east-1"             # Change to your preferred AWS region
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Create an S3 bucket for storing backups
resource "aws_s3_bucket" "backup_bucket" {
  bucket = var.s3_bucket_name
}

# Create an IAM role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "EC2RecoveryRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach a policy to allow EC2 instance access to S3
resource "aws_iam_policy_attachment" "s3_access" {
  name       = "EC2S3Access"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
# Create an IAM instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2RecoveryProfile"
  role = aws_iam_role.ec2_role.name
}

# Create an EC2 instance
resource "aws_instance" "primary_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  # Use Instance Profile instead of Role Name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "PrimaryEC2"
  }
}


