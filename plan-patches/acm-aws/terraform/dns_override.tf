resource "aws_route53_zone" "env_dns_zone" {
  count = 0
}

data "aws_route53_zone" "env_dns_zone" {
  name = "${var.system_domain}"
}

output "env_dns_zone_name_servers" {
  value = ""
}

resource "aws_route53_record" "wildcard_dns" {
  zone_id = "${data.aws_route53_zone.env_dns_zone.id}"
}

resource "aws_route53_record" "ssh" {
  zone_id = "${data.aws_route53_zone.env_dns_zone.id}"
}

resource "aws_route53_record" "bosh" {
  zone_id = "${data.aws_route53_zone.env_dns_zone.id}"
}

resource "aws_route53_record" "tcp" {
  zone_id = "${data.aws_route53_zone.env_dns_zone.id}"
}

resource "aws_iam_server_certificate" "lb_cert" {
  count = 0
}

resource "aws_acm_certificate" "cert" {
  domain_name = "*.${var.system_domain}"
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  name = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.env_dns_zone.id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}

output "certificate_arn" {
  value = "${aws_acm_certificate.cert.arn}"
}

resource "aws_elb" "cf_router_lb" {
  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 80
    lb_protocol        = "http"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${aws_acm_certificate.cert.arn}"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "tcp"
    lb_port            = 4443
    lb_protocol        = "ssl"
    ssl_certificate_id = "${aws_acm_certificate.cert.arn}"
  }
}

resource "aws_elb" "iso_router_lb" {
  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${aws_acm_certificate.cert.arn}"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "tcp"
    lb_port            = 4443
    lb_protocol        = "ssl"
    ssl_certificate_id = "${aws_acm_certificate.cert.arn}"
  }
}
