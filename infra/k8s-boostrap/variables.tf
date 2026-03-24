variable "service_account_namespace" {
  type    = string
  default = "dev"
}

variable "service_account_name" {
  type    = string
  default = "api"
}

variable "cluster_name" {
  type    = string
  default = "eks-cluster-test-dev-us-east-1"
}

variable "csi_driver_role_name" {
  type    = string
  default = "myapp-irsa-secret-reader"
}

variable "vpc_id" {
  type    = string
  default = "vpc-0a92503347a7e930c"
}

variable "region" {
  type    = string
  default = "us-east-1"
}
