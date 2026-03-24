resource "aws_iam_role" "aws_lbc_role" {
  name = format("%s-aws-lbc", data.aws_eks_cluster.this.name)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "aws_lbc_policy" {
  policy = file("policies/iam_policy.json")
  name   = "AwsLoadBalancerController"
}

resource "aws_iam_role_policy_attachment" "aws_lbc_attachment" {
  policy_arn = aws_iam_policy.aws_lbc_policy.arn
  role       = aws_iam_role.aws_lbc_role.name
}

resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name    = data.aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_lbc_role.arn
}

resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  wait       = false

  version = "3.1.0"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }
}
