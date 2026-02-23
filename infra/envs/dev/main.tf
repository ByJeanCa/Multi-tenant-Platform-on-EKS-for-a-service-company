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

module "vpc" {
  source = "../modules/vpc"

  vpc_cidr             = "10.0.0.0/16"
  common_tags          = var.common_tags
  region               = var.region
  az_count             = 2
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  db_subnet_cidrs      = ["10.0.30.0/24", "10.0.40.0/24"]
  cluster_name         = "eks-test"
}

module "eks" {
  source = "../modules/eks"

  environment        = var.environment
  region             = var.region
  private_subnets_id = module.vpc.private_subnets_id
  common_tags        = var.common_tags
}

module "ecr_repo" {
  source      = "../modules/ecr"
  common_tags = var.common_tags
}

module "db" {
  source = "../modules/rds"

  subnet_group_db_name = module.vpc.db_group_name
  vpc_id               = module.vpc.vpc_id
  common_tags          = var.common_tags
  eks_sg_id            = module.eks.eks_sg_id
}

data "tls_certificate" "eks_oidc" {
  url = module.eks.eks_oidc_issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = module.eks.eks_oidc_issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
}

locals {
  oidc_issuer_hostpath = replace(module.eks.eks_oidc_issuer, "https://", "")
}

resource "aws_iam_role" "myapp_irsa" {
  name = "myapp-irsa-secret-reader"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Action    = "sts:AssumeRoleWithWebIdentity",
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn },
      Condition = {
        StringEquals = {
          "${local.oidc_issuer_hostpath}:sub" = "system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}",
          "${local.oidc_issuer_hostpath}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "eks_csi_policy" {
  name = "secrets-csi-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect = "Allow"
        Resource = [
          module.db.db_master_secret_arn,
        "${module.db.db_master_secret_arn}*"]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "myapp_attach_csi" {
  role       = aws_iam_role.myapp_irsa.name
  policy_arn = aws_iam_policy.eks_csi_policy.arn
}