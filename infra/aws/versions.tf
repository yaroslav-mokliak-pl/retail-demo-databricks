terraform {
  required_version = ">= 1.10"

  # Bucket created by ./bootstrap. Backend blocks can't use variables.
  backend "s3" {
    bucket       = "retail-demo-dev-tfstate"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true # native S3 locking, no DynamoDB table
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}