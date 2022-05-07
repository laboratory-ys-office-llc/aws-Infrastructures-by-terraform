######################################################################
# Public Hosted Zone参照の設定
######################################################################

# 登録済みドメインをTerraformで扱えるようdata化
data "aws_route53_zone" "app_sandbox_be" {

  # 利用するドメイン名を設定
  # ※ここの値はお持ちのドメイン名に変更してください。
  name = "app-sandbox.be"
}

######################################################################
# 公開Webサーバー用ドメイン設定
# ALB用設定に変更
######################################################################

# 公開Webサーバー用のレコード構築
resource "aws_route53_record" "web" {

  # レコードを記述するホストゾーンのID
  zone_id = data.aws_route53_zone.app_sandbox_be.zone_id

  # レコード名を設定
  # data化したドメインのZone Apexをレコード登録
  name    = data.aws_route53_zone.app_sandbox_be.name

  # レコードの種類をAに設定
  type    = "A"
/*
  # TTLを300に設定
  ttl     = "300"
  # Aレコードに登録する値を設定
  # WebサーバーのパブリックIPを設定
  records = [aws_instance.web.public_ip]
*/

  # エイリアスレコードを登録
  alias {

    # ALBのNDS名を設定
    name                   = aws_lb.web.dns_name

    # ALBの所属するゾーンIDを設定
    zone_id                = aws_lb.web.zone_id

    # このレコードにヘルスチェックを行う設定
    evaluate_target_health = true
  }
}

######################################################################
# Internal Hosted Zone設定
######################################################################

# Interna Zoneの構築
resource "aws_route53_zone" "in" {

  # Zone名を設定
  # 任意の値を設定
  name = "internal"

  # 所属するVPCとリージョンを設定
  vpc {
    vpc_id = aws_vpc.vpc.id
    vpc_region = "ap-northeast-1"
  }

  # タグを設定
  tags = {
    Name = "Internal DNS Zone"
  }
}

######################################################################
# 内部APサーバー用レコード設定
######################################################################

# 内部APサーバー用のレコード構築
resource "aws_route53_record" "ap_in" {

  # レコードを記述するホストゾーンのID
  zone_id = aws_route53_zone.in.zone_id

  # レコード名を設定
  # 任意の値を設定
  name    = "ap"

  # レコードの種類をAに設定
  type    = "A"

  # TTLを300に設定
  ttl     = "300"

  # Aレコードに登録する値を設定
  # APサーバーのプライベートIPを設定
  records = [aws_instance.ap.private_ip]
}

######################################################################
# 内部RDS用レコード設定　書き込み用
######################################################################

# 内部RDSの書き込み用レコード構築
resource "aws_route53_record" "aurora_clstr_in" {


  # レコードを記述するホストゾーンのID
  zone_id = aws_route53_zone.in.zone_id

  # レコード名を設定
  # 任意の値を設定
  name    = "rds"

  # レコードの種類をCNAMEに設定
  type    = "CNAME"

  # TTLを300に設定
  ttl     = "300"

  # CNAMEレコードに登録する値を設定
  # RDSの書き込み用エンドポイントを設定
  records = [aws_rds_cluster.aurora_clstr.endpoint]
}

######################################################################
# 内部RDS用レコード設定 読み込み用
######################################################################

# 内部RDSの読み込み用レコード構築
resource "aws_route53_record" "aurora_clstr_ro_in" {

  # レコードを記述するホストゾーンのID
  zone_id = aws_route53_zone.in.zone_id

  # レコード名を設定
  # 任意の値を設定
  name    = "rds-ro"

  # レコードの種類をCNAMEに設定
  type    = "CNAME"

  # TTLを300に設定
  ttl     = "300"

  # CNAMEレコードに登録する値を設定
  # RDSの読み込み用エンドポイントを設定
  records = [aws_rds_cluster.aurora_clstr.reader_endpoint]
}

######################################################################
# ACM用DNS検証設定
######################################################################

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for domain_validation_option in aws_acm_certificate.cert.domain_validation_options : domain_validation_option.domain_name => {
      name   = domain_validation_option.resource_record_name
      record = domain_validation_option.resource_record_value
      type   = domain_validation_option.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.app_sandbox_be.zone_id
}
