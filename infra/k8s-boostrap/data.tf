data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  name       = var.cluster_name
}

data "aws_iam_role" "csi_driver" {
  name = var.csi_driver_role_name
}