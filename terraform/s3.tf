# Buckets
## Receive Bucket for RelayShip
resource "aws_s3_bucket" "receive" {
  bucket = "be-s3-${var.system}-receive-${var.env}"
}

### public_access_block
resource "aws_s3_bucket_public_access_block" "receive" {
  bucket                  = aws_s3_bucket.receive.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

### event notification
resource "aws_s3_bucket_notification" "receive" {
  count       = var.env == "dev" ? 1 : 0
  bucket      = aws_s3_bucket.receive.bucket
  eventbridge = true
}

### versioning
resource "aws_s3_bucket_versioning" "receive" {
  bucket = aws_s3_bucket.receive.id
  versioning_configuration {
    status = "Enabled"
  }
}

### server_side_encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "receive" {
  bucket = aws_s3_bucket.receive.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kif.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

## kms key
resource "aws_kms_key" "kif" {
  enable_key_rotation = true
  tags = {
    Name       = "be-cmk-${var.system}-01-${lower(var.env)}"
    SystemName = var.systemname
  }
  lifecycle {
    ignore_changes = [
      enable_key_rotation
    ]
  }
}

### key policy
resource "aws_kms_key_policy" "kif" {
  key_id = aws_kms_key.kif.id
  # TODO: templatefile化
  policy = file(var.kms-kif)
}

resource "aws_kms_alias" "kif" {
  name          = "alias/be-cmk-${var.system}-01-${var.env}"
  target_key_id = aws_kms_key.kif.key_id
}

## logging
resource "aws_s3_bucket_logging" "receive" {
  bucket        = aws_s3_bucket.receive.id
  target_bucket = aws_s3_bucket.log.id
  target_prefix = "AWSLogs/${data.aws_caller_identity.self.account_id}/${aws_s3_bucket.receive.id}/"
}

## lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "receive" {
  bucket = aws_s3_bucket.receive.id

  rule {
    id = "receive"

    expiration {
      days = var.bucket.receive.expire
    }

    status = "Enabled"
  }
}

## bucket policy
resource "aws_s3_bucket_policy" "receive" {
  bucket = aws_s3_bucket.receive.id
  #TODO: data or templatefile
  policy = file(var.receive-policy)
}

# send bucket
resource "aws_s3_bucket" "send" {
  bucket = "be-s3-${var.system}-send-${var.env}"
}

### public_access_block
resource "aws_s3_bucket_public_access_block" "send" {
  bucket                  = aws_s3_bucket.send.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

### server_side_encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "send" {
  bucket = aws_s3_bucket.send.id
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kif.arn
      sse_algorithm     = "aws:kms"
    }
  }
  lifecycle {
    ignore_changes = [
      rule
    ]
  }
}

resource "aws_s3_bucket_policy" "send" {
  bucket = aws_s3_bucket.send.id
  #TODO: data or templatefile
  policy = file(var.send-policy)
}

resource "aws_s3_bucket_logging" "send" {
  bucket        = aws_s3_bucket.send.id
  target_bucket = aws_s3_bucket.log.id
  target_prefix = "AWSLogs/${data.aws_caller_identity.self.account_id}/${aws_s3_bucket.send.id}/"
}

# STG/PRGはRelayship.tf 内RSv3で設定するため、ここでは設定しない
resource "aws_s3_bucket_notification" "send" {
  count       = var.env == "dev" ? 1 : 0
  bucket      = aws_s3_bucket.send.bucket
  eventbridge = true
}
## Log Bucket
resource "aws_s3_bucket" "log" {
  bucket = "be-${var.system}-log-${var.env}"
}

### public_access_block
resource "aws_s3_bucket_public_access_block" "log" {
  bucket                  = aws_s3_bucket.log.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

### versioning
resource "aws_s3_bucket_versioning" "log" {
  bucket = aws_s3_bucket.log.id
  versioning_configuration {
    status = "Disabled"
  }
}

### server_side_encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "log" {
  bucket = aws_s3_bucket.log.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

### bucket_policy (allow put object from log source bucket)
resource "aws_s3_bucket_policy" "allow_logging" {
  bucket = aws_s3_bucket.log.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowS3ServerAccessLogToSourceBucket",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "logging.s3.amazonaws.com"
        },
        "Action" : [
          "s3:PutObject"
        ],
        "Resource" : "${aws_s3_bucket.log.arn}/*"
        "Condition" : {
          "StringEquals" : {
            "aws:SourceAccount" : data.aws_caller_identity.self.account_id
          }
        }
      }
    ]
  })
}

## Storage Bucket
resource "aws_s3_bucket" "storage" {
  bucket = "be-${var.system}-storage-${var.env}"
}

### public_access_block
resource "aws_s3_bucket_public_access_block" "storage" {
  bucket                  = aws_s3_bucket.storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

### versioning
resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

### server_side_encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    id = "original"

    expiration {
      days = var.bucket.storage.expire
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "storage" {
  bucket      = aws_s3_bucket.storage.bucket
  eventbridge = true
}

## logging
resource "aws_s3_bucket_logging" "storage" {
  bucket        = aws_s3_bucket.storage.id
  target_bucket = aws_s3_bucket.log.id
  target_prefix = "AWSLogs/${data.aws_caller_identity.self.account_id}/${aws_s3_bucket.storage.id}/"
}

## IF Import Bucket
resource "aws_s3_bucket" "import" {
  bucket = "be-kif-import-${var.env}"
}

### public_access_block
resource "aws_s3_bucket_public_access_block" "import" {
  bucket                  = aws_s3_bucket.import.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

### versioning
resource "aws_s3_bucket_versioning" "import" {
  bucket = aws_s3_bucket.import.id
  versioning_configuration {
    status = "Enabled"
  }
}

### server_side_encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "import" {
  bucket = aws_s3_bucket.import.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

### bucket policy
data "aws_iam_policy_document" "import" {
  source_policy_documents = concat(
    [data.aws_iam_policy_document.import-base.json],
    [for policy in data.aws_iam_policy_document.import-vpces : policy.json],
    # b-retail, eob向け*-pf/*へのアクセスを許可設定, */if/*に移行後削除
    [data.aws_iam_policy_document.bretail-access.json],
    [data.aws_iam_policy_document.eob-access.json],
  )
}

data "aws_iam_policy_document" "import-base" {
  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.import.arn,
      "${aws_s3_bucket.import.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "import" {
  bucket = aws_s3_bucket.import.id
  policy = data.aws_iam_policy_document.import.json
}
### event notification
resource "aws_s3_bucket_notification" "import" {
  count       = var.env == "dev" ? 1 : 0
  bucket      = aws_s3_bucket.import.bucket
  eventbridge = true
}
