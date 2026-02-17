variable "vpc_cidr" {
  type = string
}

variable "common_tags" {
  type = map(string)
  default = {
    "environment" = "dev"
  }
}

variable "region" {
  type = string
}

variable "az_count" {
  type        = number
  description = "Amount of availabilities zone you want"
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "db_subnet_cidrs" {
  type = list(string)
}

variable "cluster_name" {
  type = string
}