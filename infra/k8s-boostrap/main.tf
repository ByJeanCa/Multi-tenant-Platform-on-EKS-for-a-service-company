terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.29"
    }
  }
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  name       = var.cluster_name
}

data "aws_iam_role" "target" {
  name = var.role_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

resource "kubernetes_namespace" "dev" {
  metadata {
      name = var.service_account_namespace
  }
}

resource "kubernetes_service_account" "api" {
  metadata {
    name = var.service_account_name
    namespace = kubernetes_namespace.dev.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" = data.aws_iam_role.target.arn
    }
  }
}