resource "helm_release" "aws_external_dns"{
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
    name = "serviceAccount.name"
    value = "external-dns-controller"
  }

  set_list {
    name = "sources"
    value = ["ingress"]
  }

  set_list {
    name = "domainFilters"
    value = ["veliacr.com"]
  }

  set {
    name = "txtOwnerId"
    value = var.cluster_name
  }
}