###############################################
# Route53 Hosted Zone (if not already existing)
###############################################
resource "aws_route53_zone" "main" {
  name = var.domain_name
}

###############################################
# Record for Environment (ALB)
###############################################
resource "aws_route53_record" "env_record" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "${var.env}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
