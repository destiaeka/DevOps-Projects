resource "aws_route53_zone" "main" {
  name = "tekasa.web.id"
}

resource "aws_route53_record" "nlb" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.tekasa.web.id"
  type    = "A"

  alias {
    name                   = aws_lb.lb-app.dns_name
    zone_id               = aws_lb.lb-app.zone_id
    evaluate_target_health = true
  }
}

