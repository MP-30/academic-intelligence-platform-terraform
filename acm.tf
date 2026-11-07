resource "aws_acm_certificate" "main" {
  domain_name               = "${var.ui_subdomain}.${var.domain_name}"
  subject_alternative_names = ["${var.api_subdomain}.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${var.project}-cert" }
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn

  timeouts {
    create = "45m"
  }
}