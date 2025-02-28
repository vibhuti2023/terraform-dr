# Terraform configuration for Complete Disaster Recovery (DR) Setup on AWS

provider "aws" {
  region = var.region
}

# S3 Bucket for Backups with Lifecycle Policy
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

# IAM Role for Lambda to Start/Stop DR EC2 Instances
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-dr-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_policy" "lambda_ec2_permissions" {
  name        = "LambdaEC2Permissions"
  description = "Allows Lambda to manage EC2 instances"
  
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_ec2_permissions.arn
}

# Lambda Function to Start/Stop DR EC2 Instances
resource "aws_lambda_function" "start_stop_dr" {
  filename         = "lambda.zip"
  function_name = "DR_EC2_Control"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout          = 60
}

# Spot Instance for DR EC2
resource "aws_instance" "dr_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  spot_price    = "0.05"

  tags = {
    Name = "DR-Instance"
  }
}

# RDS Snapshot Replication
resource "aws_db_snapshot" "rds_snapshot" {
  db_instance_identifier = var.rds_instance_id
  db_snapshot_identifier = "${var.rds_instance_id}-snapshot"
}

# Route 53 Failover Setup
resource "aws_route53_record" "failover_primary" {
  zone_id = var.route53_zone_id
  name    = "primary.example.com"
  type    = "A"
  set_identifier = "primary"
  failover_routing_policy {
    type = "PRIMARY"
  }
  records = [var.primary_ip]
  ttl     = 60
}

resource "aws_route53_record" "failover_secondary" {
  zone_id = var.route53_zone_id
  name    = "secondary.example.com"
  type    = "A"
  set_identifier = "secondary"
  failover_routing_policy {
    type = "SECONDARY"
  }
  records = [var.secondary_ip]
  ttl     = 60
}

# CloudWatch Alarms & SNS Notifications
resource "aws_sns_topic" "dr_alerts" {
  name = "dr-alerts"
}

resource "aws_cloudwatch_metric_alarm" "ec2_down_alarm" {
  alarm_name          = "EC2-Down-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = 60
  statistic          = "Average"
  threshold         = 1
  alarm_actions      = [aws_sns_topic.dr_alerts.arn]
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
