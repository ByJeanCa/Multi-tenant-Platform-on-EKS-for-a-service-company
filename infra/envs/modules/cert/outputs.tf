output "nameservers" {
  value = aws_route53_zone.web_domain.name_servers
}

output "cert_arn" {
  value = aws_acm_certificate.cert.arn
}