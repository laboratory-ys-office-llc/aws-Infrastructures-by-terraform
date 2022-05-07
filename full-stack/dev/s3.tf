######################################################################
# Public(公開設定) のバケット
######################################################################

# S3バケットのリソースを"public_bucket"という名称で作成
resource "aws_s3_bucket" "public_bucket" {

  # バケット名称を任意の名前で定義
  # ※ここの値は変更してください。バケット名は全世界で一意である必要があります
  bucket        = "instance-coffee-bucket-ys-office-llc"

  # このリソースをterraform destroyで削除可能に設定
  force_destroy = true
}

######################################################################
# Private（非公開設定） のバケット
######################################################################

# S3バケットのリソースを"private_bucket"という名称で作成
resource "aws_s3_bucket" "private_bucket" {

  # バケット名称を任意の名前で定義
  # ※ここの値は変更してください。バケット名は全世界で一意である必要があります
  bucket        = "instance-coffee-app-bucket-ys-office-llc"

  # このリソースをterraform destroyで削除可能に設定
  force_destroy = true

  # タグを設定
  tags = {
    Name = "instance-coffee-app-bucket"
  }
}

######################################################################
# ALBアクセスログ配置用S3バケットの設定
######################################################################

# ログ配置用S3バケットを構築
resource "aws_s3_bucket" "alb_access_log" {

  # バケット名称を任意の名前で定義
  # ※ここの値は変更してください。バケット名は全世界で一意である必要があります
  bucket = "alb-access-log-ys-office-llc"

  # このリソースをterraform destroyで削除可能に設定
  force_destroy = true

  # タグを設定
  tags = {
    Name = "alb-access-log"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_access_log" {
  bucket = aws_s3_bucket.alb_access_log.id

  rule {
    id = "rule-1"

    filter {}

    expiration {
      days = 90
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_cors_configuration" "public_bucket" {
  bucket = aws_s3_bucket.public_bucket.id

  # クロスオリジンリソースシェアリングのルール設定
  # 特定のオリジン（URL）に対しアクセスを許可する設定
  cors_rule {

    # アクセス元のオリジンを制限。ここで設定している["*"]は制限無し
    # 特定のオリジンで制限するなら以下設定
    # allowed_origins = ["https://hoge.com"]
    allowed_origins = ["*"]

    # 許容するHTTPメソッドのリクエストを制限
    # 読み取り専用のコンテンツのみであれば、セキュリティ上["GET"]のみとすべき
    # 複数のメソッドを定義可能。以下が対応
    # ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    allowed_methods = ["GET"]

    # 許容するHTTPヘッダーを制限。特定のヘッダー情報で制限
    # 特に条件がなければ["*"]で問題ない
    allowed_headers = ["*"]

    # ブラウザのキャッシュ時間。秒単位で定義可能
    # 特に条件がないため、公式の例に則り3000を設定
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_acl" "public_bucket" {
  bucket = aws_s3_bucket.public_bucket.id
  # S3のACL(アクセスコントロールリスト)を設定
  # パブリック読み取り専用アクセスのみ許可
  acl           = "public-read"
}

resource "aws_s3_bucket_acl" "private_bucket" {
  bucket = aws_s3_bucket.private_bucket.id
  # S3のACL(アクセスコントロールリスト)を設定
  # AWS環境上からのアクセスのみ許可
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "private_bucket" {
  bucket = aws_s3_bucket.private_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private_bucket" {
  bucket = aws_s3_bucket.private_bucket.id
  # 暗号化を有効に設定
  rule {
    apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_access_log" {
  bucket = aws_s3_bucket.alb_access_log.id
  policy = data.aws_iam_policy_document.alb_access_log.json
}

data "aws_iam_policy_document" "alb_access_log" {
  statement {
    sid       = "1"
    effect    = "Allow"
    resources = ["arn:aws:s3:::alb-access-log-ys-office-llc/*"]
    actions   = ["s3:PutObject"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::582318560864:root"]
    }
  }

  statement {
    sid       = "2"
    effect    = "Allow"
    resources = ["arn:aws:s3:::alb-access-log-ys-office-llc/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid       = "3"
    effect    = "Allow"
    resources = ["arn:aws:s3:::alb-access-log-ys-office-llc"]
    actions   = ["s3:GetBucketAcl"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}
