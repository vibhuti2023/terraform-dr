terraform {
  backend "s3" {
    bucket         = "my-dr-backups"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  region = "ap-southeast-2"  # Ensure this matches your S3 bucket's region
}


resource "aws_s3_bucket" "dr_backup" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_lifecycle_configuration" "dr_backup_lifecycle" {
  bucket = aws_s3_bucket.dr_backup.id

  rule {
    id     = "delete-old-backups"
    status = "Enabled"

    expiration {
      days = var.s3_retention_days
    }
  }
}

resource "aws_instance" "dr_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
}

resource "aws_lambda_function" "dr_lambda" {
  filename         = "lambda_function.zip"
  function_name    = "DisasterRecoveryLambda"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
}

resource "aws_route53_record" "failover_record" {
  zone_id = var.route53_zone_id
  name    = "failover.example.com"
  type    = "A"
  ttl     = 60
  records = [var.secondary_ip]
}

variable "region" {}
variable "s3_bucket_name" {}
variable "s3_retention_days" {}
variable "ami_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "rds_instance_id" {}
variable "route53_zone_id" {}
variable "primary_ip" {}
variable "secondary_ip" {}
