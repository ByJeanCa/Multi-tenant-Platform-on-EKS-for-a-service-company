output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets_id" {
  value = [for k in sort(keys(aws_subnet.public)) : aws_subnet.public[k].id]
}

output "private_subnets_id" {
  value = [for k in sort(keys(aws_subnet.private)) : aws_subnet.private[k].id]
}

output "db_subnets_id" {
  value = [for k in sort(keys(aws_subnet.db)) : aws_subnet.db[k].id]
}
