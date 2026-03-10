terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
}

resource "aws_iam_role" "cluster" {
  name = "eks-cluster-test-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_eks_cluster" "main" {
  name = var.name

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  role_arn = aws_iam_role.cluster.arn
  version  = "1.34"

  vpc_config {
    subnet_ids              = var.private_subnets_id
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  ]

  tags = var.common_tags
}

resource "aws_iam_role" "nodes" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}


resource "aws_eks_node_group" "apps-ng" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = format("node-apps-ng-%s", var.environment)
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.private_subnets_id

  capacity_type = "ON_DEMAND"
  instance_types = ["t3a.medium"]

  labels = {
    role = "app"
  }

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy
  ]

  tags = var.common_tags
}

resource "aws_eks_node_group" "system-ng" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = format("node-system-ng-%s", var.environment)
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.private_subnets_id

  capacity_type = "ON_DEMAND"
  instance_types = ["t3a.medium"]

  labels = {
    role = "system"
  }

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy
  ]

  tags = var.common_tags
}

resource "aws_iam_role" "aws_lbc_role" {
  name = format("%s-aws-lbc", aws_eks_cluster.main.name)

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
  policy = file("${path.module}/iam_policy.json")
  name = "AwsLoadBalancerController"
}

resource "aws_iam_role_policy_attachment" "aws_lbc_attachment" {
  policy_arn = aws_iam_policy.aws_lbc_policy.arn
  role = aws_iam_role.aws_lbc_role.name
}

resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name = aws_eks_cluster.main.name
  namespace = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn = aws_iam_role.aws_lbc_role.arn
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.main.name
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
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
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
  cluster_name = aws_eks_cluster.main.name
  namespace = "kube-system"
  service_account = "external-dns-controller"
  role_arn = aws_iam_role.external-dns-controller.arn
}