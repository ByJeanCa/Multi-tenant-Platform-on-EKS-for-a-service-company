output "db_master_secret_arn" {
  value = aws_db_instance.default.master_user_secret[0].secret_arn
}

output "db_endpoint" {
  value = aws_db_instance.default.endpoint
}

output "db_identifier" {
  value = aws_db_instance.default.identifier
}