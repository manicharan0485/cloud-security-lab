terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # In real use: a remote backend with locking (e.g. S3 + DynamoDB, or
  # Terraform Cloud) so state can't be corrupted by concurrent applies.
  # backend "s3" {
  #   bucket         = "your-tfstate-bucket"
  #   key            = "cloud-security-lab/terraform.tfstate"
  #   region         = "eu-central-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}
