resource "aws_iam_openid_connect_provider" "eks" {
  url             = data.tls_certificate.eks_oidc.url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]

}

locals {
  oidc_issuer_hostpath = replace(data.tls_certificate.eks_oidc.url, "https://", "")
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
          data.aws_secretsmanager_secret.db_master.arn,
        "${data.aws_secretsmanager_secret.db_master.arn}*"]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "myapp_attach_csi" {
  role       = aws_iam_role.myapp_irsa.name
  policy_arn = aws_iam_policy.eks_csi_policy.arn
}

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
      "eks.amazonaws.com/role-arn" = aws_iam_role.myapp_irsa.arn
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