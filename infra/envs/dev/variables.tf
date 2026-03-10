variable "region" {
  type    = string
  default = "us-east-1"
}

variable "common_tags" {
  type = map(string)
  default = {
    "environment" = "dev"
  }
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "service_account_namespace" {
  type    = string
  default = "dev"
}

variable "service_account_name" {
  type    = string
  default = "api"
}

variable "domain" {
  type = string
  default = "veliacr.com"
}