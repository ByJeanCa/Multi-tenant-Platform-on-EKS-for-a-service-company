resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = data.aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.21.1-eksbuild.3"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  configuration_values = jsonencode({
    enableNetworkPolicy = "true"
  })
}