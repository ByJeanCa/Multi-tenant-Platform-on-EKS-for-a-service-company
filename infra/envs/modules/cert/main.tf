resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain
  validation_method = "DNS"

  tags = var.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "web_domain" {
  name = var.domain

  tags = var.common_tags
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for o in aws_acm_certificate.cert.domain_validation_options : o.domain_name => {
      name  = o.resource_record_name
      type  = o.resource_record_type
      value = o.resource_record_value
    }
  }
  zone_id = aws_route53_zone.web_domain.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [ for record in aws_route53_record.acm_validation : record.fqdn ]
}

data "aws_acm_certificate" "issued" {
  domain      = var.domain
  types       = ["AMAZON_ISSUED"]
  statuses    = ["ISSUED"]
  most_recent = true
  depends_on  = [aws_acm_certificate_validation.cert]
}