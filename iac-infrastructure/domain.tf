data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

locals {
  app_fqdn    = "app.${var.domain_name}"
  origin_fqdn = "origin.${var.domain_name}"
}

# Certyfikat dla CloudFront (musi być w us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us_east_1
  domain_name       = local.app_fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Certyfikat dla ALB (eu-central-1): nazwa aplikacji i nazwa origin
resource "aws_acm_certificate" "alb" {
  domain_name               = local.app_fqdn
  subject_alternative_names = [local.origin_fqdn]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # Ten sam rekord CNAME dla tej samej nazwy: scalamy po nazwie domeny
  validation_records = merge(
    { for o in aws_acm_certificate.cloudfront.domain_validation_options : o.domain_name => o },
    { for o in aws_acm_certificate.alb.domain_validation_options : o.domain_name => o },
  )
}

resource "aws_route53_record" "cert_validation" {
  for_each = local.validation_records

  zone_id         = data.aws_route53_zone.this.zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [
    for o in aws_acm_certificate.cloudfront.domain_validation_options : aws_route53_record.cert_validation[o.domain_name].fqdn
  ]
}

resource "aws_acm_certificate_validation" "alb" {
  certificate_arn = aws_acm_certificate.alb.arn
  validation_record_fqdns = [
    for o in aws_acm_certificate.alb.domain_validation_options : aws_route53_record.cert_validation[o.domain_name].fqdn
  ]
}