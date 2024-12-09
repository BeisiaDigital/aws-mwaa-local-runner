# transfer from export buckets
resource "aws_cloudwatch_event_rule" "put_dlk" {
  name        = "${var.system}-put_dlk-${var.env}"
  description = "put dlk"
  event_pattern = jsonencode({
    "detail-type" : ["Object Created"],
    "source" : ["aws.s3"],
    "detail" : {
      "bucket" : {
        "name" : [aws_s3_bucket.storage.bucket]
      }
      "object" : {
        "key" : [{
          "prefix" : "original/"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "put_dlk" {
  rule = aws_cloudwatch_event_rule.put_dlk.name
  arn  = aws_sqs_queue.put_dlk.arn

  sqs_target {
    message_group_id = "put_dlk"
  }
}

resource "aws_sqs_queue" "put_dlk" {
  name                        = "${var.system}-put_dlk-${var.env}.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perMessageGroupId"
  visibility_timeout_seconds  = 300
}

data "aws_iam_policy_document" "sqs_put_dlk" {
  statement {
    sid    = "admin"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.self.account_id}:${var.SSO.AdministratorRole}"]
    }

    actions   = ["SQS:*"]
    resources = [aws_sqs_queue.put_dlk.arn]
  }
  statement {
    sid    = "put_dlk"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.put_dlk.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.put_dlk.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "put_dlk" {
  queue_url = aws_sqs_queue.put_dlk.id
  policy    = data.aws_iam_policy_document.sqs_put_dlk.json
}
