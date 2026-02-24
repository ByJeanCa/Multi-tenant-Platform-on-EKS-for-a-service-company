output "eks_sg_id" {
  value = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "eks_name" {
  value = aws_eks_cluster.main.name
}

output "eks_oidc_issuer" {
  value = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}