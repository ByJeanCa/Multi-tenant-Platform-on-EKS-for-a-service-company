output "db_endpoint" {
  value = module.db.db_endpoint
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "rds_secret_arn" {
  value = module.db.db_master_secret_arn
}

output "cert_arn" {
  value = module.cert.cert_arn
}