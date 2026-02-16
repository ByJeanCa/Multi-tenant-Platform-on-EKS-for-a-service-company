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

module "vpc" {
  source = "../modules/vpc"

  vpc_cidr             = "10.0.0.0/16"
  common_tags          = var.common_tags
  region               = var.region
  az_count             = 2
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  db_subnet_cidrs      = ["10.0.30.0/24", "10.0.40.0/24"]
  cluster_name = "eks-test"
}

module "eks" {
  source = "../modules/eks"

  environment = var.environment
  region = var.region
  private_subnets_id = module.vpc.private_subnets_id
}