######################################################################
# 証明書の設定
######################################################################

# 証明書を構築
resource "aws_acm_certificate" "cert" {
  domain_name               = "app-sandbox.be"
  subject_alternative_names = ["*.app-sandbox.be"]
  validation_method         = "DNS"
}

######################################################################
# 証明書の検証設定
######################################################################

# Route53レコード検証成否を確認
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
