provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0" # Update with latest Amazon Linux AMI
  instance_type = "t2.micro"

  tags = {
    Name = "DR-Web-Instance"
  }
}

resource "aws_s3_bucket" "dr_bucket" {
  bucket = "terraform-dr-backup-bucket-123"  # Change to a unique bucket name
  acl    = "private"
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

