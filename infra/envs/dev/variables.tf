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
  type = string
  default = "dev"
}