resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = data.aws_eks_cluster.this.name
  addon_name   = "eks-pod-identity-agent"
}

resource "aws_iam_policy" "external_dns" {
  name = "external_dns_iam_policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ChangeResourceRecordSets"
        ],
        "Resource" : [
          "arn:aws:route53:::hostedzone/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "external-dns-controller" {
  name = "external-dns-controller"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "pods.eks.amazonaws.com"
        },
        "Action" : [
          "sts:TagSession",
          "sts:AssumeRole"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach-dns-controller-policy" {
  policy_arn = aws_iam_policy.external_dns.arn
  role       = aws_iam_role.external-dns-controller.name
}

resource "aws_eks_pod_identity_association" "external-dns-controller" {
  cluster_name    = data.aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = "external-dns-controller"
  role_arn        = aws_iam_role.external-dns-controller.arn
}

resource "helm_release" "aws_external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  namespace  = "kube-system"
  wait       = false

  version = "1.15.0"

  set {
    name  = "provider.name"
    value = "aws"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns-controller"
  }

  set_list {
    name  = "sources"
    value = ["ingress"]
  }

  set_list {
    name  = "domainFilters"
    value = ["veliacr.com"]
  }

  set {
    name  = "txtOwnerId"
    value = var.cluster_name
  }
}