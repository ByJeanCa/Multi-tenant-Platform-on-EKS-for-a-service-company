output "nameservers" {
  value = aws_route53_zone.web_domain.name_servers
}