resource "kubernetes_namespace" "csi_driver" {
  metadata {
    name = var.service_account_namespace
  }
}

resource "kubernetes_service_account" "csi_driver" {
  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace.csi_driver.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" = data.aws_iam_role.csi_driver.arn
    }
  }
}