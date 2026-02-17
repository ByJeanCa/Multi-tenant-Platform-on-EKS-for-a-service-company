variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "private_subnets_id" {
  type = list(string)
}

variable "common_tags" {
  type = map(string)
  default = {
    "environment" = "dev"
  }
}
