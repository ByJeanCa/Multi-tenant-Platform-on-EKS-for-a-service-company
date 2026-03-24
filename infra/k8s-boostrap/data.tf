data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  name = var.cluster_name
}

data "tls_certificate" "eks_oidc" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

data "aws_db_instance" "db" {
  db_instance_identifier = "terraform-20260324194527181400000005"
}

data "aws_secretsmanager_secret" "db_master" {
  arn = data.aws_db_instance.db.master_user_secret[0].secret_arn
}
