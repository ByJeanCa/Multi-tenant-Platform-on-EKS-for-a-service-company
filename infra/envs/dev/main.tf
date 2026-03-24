terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "default"
}
locals {
  cluster_name = format("eks-cluster-test-%s-%s", var.environment, var.region)
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
  cluster_name = local.cluster_name
}

module "cert" {
  source = "../modules/cert"

  domain = var.domain
  common_tags = var.common_tags
}

module "eks" {
  source = "../modules/eks"

  environment        = var.environment
  region             = var.region
  private_subnets_id = module.vpc.private_subnets_id
  common_tags        = var.common_tags
  name = local.cluster_name
}

module "ecr_repo" {
  source      = "../modules/ecr"
  common_tags = var.common_tags
  image_names = ["worker", "api", "frontend"]
}

module "db" {
  source = "../modules/rds"

  subnet_group_db_name = module.vpc.db_group_name
  vpc_id               = module.vpc.vpc_id
  common_tags          = var.common_tags
  eks_sg_id            = module.eks.eks_sg_id
}
