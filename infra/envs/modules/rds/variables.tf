variable "subnet_group_db_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "eks_sg_id" {
  type = string
}

