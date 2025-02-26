provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  ami           = "ami-01184db239e4c756c" # Use latest Amazon Linux AMI
  instance_type = "t2.micro"

  instance_market_options {
    market_type = "spot"
  }

  tags = {
    Name = "DR-Web-Instance"
  }
}

resource "aws_s3_bucket" "dr_bucket" {
  bucket = "terraform-dr-backup-bucket-123"
  acl    = "private"  # or public-read, public-read-write, etc.
}

resource "aws_sns_topic" "alert_topic" {
  name = "dr-alerts"
}

resource "aws_lambda_function" "dr_lambda" {
  filename      = "lambda_function.zip"
  function_name = "drLambdaFunction"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "python3.8"
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        }
      }
    ]
  }
  EOF
}
resource "aws_iam_role" "lambda_ec2_control" {
  name = "lambda_ec2_control"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        }
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "lambda_ec2_policy" {
  name        = "lambda_ec2_policy"
  description = "Policy to start and stop EC2 instances"
  policy      = <<EOF
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

resource "aws_iam_role_policy_attachment" "lambda_ec2_attach" {
  role       = aws_iam_role.lambda_ec2_control.name
  policy_arn = aws_iam_policy.lambda_ec2_policy.arn
}
resource "aws_s3_bucket_lifecycle_configuration" "dr_backup_lifecycle" {
  bucket = aws_s3_bucket.dr_bucket.id

  rule {
    id = "delete-old-backups"
    status = "Enabled"

    expiration {
      days = 30  # Automatically delete backups older than 30 days
    }
  }
}

