provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "backend_bucket" {
  bucket = "eks-bucket-${var.project_name}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "state_lock" {
  name         = "eks-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}