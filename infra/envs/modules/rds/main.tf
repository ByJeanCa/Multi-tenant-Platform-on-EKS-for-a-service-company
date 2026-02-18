terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>6.0"
    }
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "db-sg"
  vpc_id      = var.vpc_id

  tags = var.common_tags
}

resource "aws_security_group_rule" "db_from_app" {
  type = "ingress"
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  security_group_id = aws_security_group.rds_sg.id
  source_security_group_id = var.eks_sg_id
}

resource "aws_db_instance" "default" {
  allocated_storage    = 5
  db_name              = "db_test"
  engine               = "postgres"
  engine_version       = "17.6"
  instance_class       = "db.t3.micro"
  username             = "postgres"
  manage_master_user_password = true
  skip_final_snapshot  = true #cambiar en prod

  db_subnet_group_name = var.subnet_group_db_name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = false
  storage_encrypted     = true
}