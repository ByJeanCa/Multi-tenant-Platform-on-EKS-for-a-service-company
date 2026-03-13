resource "helm_release" "csi_secrets_store" {
  name       = "csi-secrets-store"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  wait       = false
}

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

resource "helm_release" "aws_secrets_provider" {
  name       = "secrets-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"

  set {
  name  = "secrets-store-csi-driver.install"
  value = "false"
  }

  depends_on = [
    helm_release.csi_secrets_store
  ]
}