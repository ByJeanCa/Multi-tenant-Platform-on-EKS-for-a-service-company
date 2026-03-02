terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "default"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "remote_backend" {
  bucket = format("eks-tfstate-%s-%s", data.aws_caller_identity.current.account_id, var.region)

  tags = {
    Name        = format("eks-tfstate-%s-%s", data.aws_caller_identity.current.account_id, var.region)
    Environment = "Dev"
  }

  lifecycle {
    prevent_destroy = true
  }
}
