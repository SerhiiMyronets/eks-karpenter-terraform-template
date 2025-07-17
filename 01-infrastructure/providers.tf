terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
  backend "s3" {
    bucket         = "eks-bucket-template"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "eks-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

}