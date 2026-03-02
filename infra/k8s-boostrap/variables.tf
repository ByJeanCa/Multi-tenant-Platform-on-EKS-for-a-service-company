variable "service_account_namespace" {
  type    = string
  default = "dev"
}

variable "service_account_name" {
  type    = string
  default = "api"
}

variable "cluster_name" {
  type = string
  default = "EKS-Cluster-test-dev-us-east-1"
}

variable "role_name" {
  type = string
  default = "myapp-irsa-secret-reader"
}