variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "public_subnets_id" {
  type = list(string)
}

variable "private_subnets_id" {
  type = list(string)
}