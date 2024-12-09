resource "aws_iam_role" "prober" {
  count = var.env == "prd" ? 0 : 1

  name = "${var.system}-prober-${var.env}"
  managed_policy_arns = [
    data.aws_iam_policy.CloudWatchReadOnlyAccess.arn,
    data.aws_iam_policy.CloudWatchLogsReadOnlyAccess.arn,
    aws_iam_policy.prober.arn
  ]

  assume_role_policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.self.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringLike = {
            "aws:userid" = [
              for id in var.prober_sso_roleid : "${id}:*"
            ]
          }
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "prober_policy" {
  statement {
    sid    = "Buckets"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:GetBucket",
      "s3:List*"
    ]
    resources = [
      aws_s3_bucket.receive.arn,
      "${aws_s3_bucket.receive.arn}/*",
      aws_s3_bucket.storage.arn,
      "${aws_s3_bucket.storage.arn}/*",
      aws_s3_bucket.send.arn,
      "${aws_s3_bucket.send.arn}/*",
      # data.aws_s3_bucket.dlk.arn,
      # "${data.aws_s3_bucket.dlk.arn}/*",
      "arn:aws:s3:::be-*-export-${var.env}",
      "arn:aws:s3:::be-*-export-${var.env}/*",
      "arn:aws:s3:::be-*-import-${var.env}",
      "arn:aws:s3:::be-*-import-${var.env}/*",
    ]
  }
  statement {
    sid    = "ToUseReceiveSendBucket"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt"
    ]
    resources = [aws_kms_key.kif.arn]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values = [
        "s3.ap-northeast-1.amazonaws.com",
      ]
    }
  }
  statement {
    sid    = "ReadMWAAlogs"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [aws_kms_key.kif.arn]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values = [
        "logs.ap-northeast-1.amazonaws.com",
        "logs.ap-northeast-1.api.aws"
      ]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "sqs:GetQueueAttributes"
    ]
    resources = [
      # TODO: receive/transferのみにする
      "arn:aws:sqs:ap-northeast-1:${data.aws_caller_identity.self.account_id}:be-kif-sqs-${upper(var.env)}-0?-*.fifo",
      aws_sqs_queue.transfer.arn
    ]
  }
  # mock-* は devでのみ使用する
  statement {
    sid    = "MockBuckets"
    effect = var.env == "dev" ? "Allow" : "Deny"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:GetBucket",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::be-mock-*",
      "arn:aws:s3:::be-mock-*/*"
    ]
  }

}

resource "aws_iam_policy" "prober" {
  name   = "${var.system}-prober-${var.env}"
  policy = data.aws_iam_policy_document.prober_policy.json
}
