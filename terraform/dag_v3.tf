# from kif-import
resource "aws_cloudwatch_event_rule" "v3_import" {
  name        = "${var.system}-v3-${var.system}-${var.env}"
  description = "ifv3"
  event_pattern = jsonencode({
    "detail-type" : ["Object Created"],
    "source" : ["aws.s3"],
    "detail" : {
      "bucket" : {
        "name" : [aws_s3_bucket.import.bucket]
      },
      "object" : {
        "key" : [{
          "wildcard" : "*/if/*/*"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "v3_import" {
  rule = aws_cloudwatch_event_rule.v3_import.name
  arn  = aws_sqs_queue.v3.arn

  sqs_target {
    message_group_id = "v3_kif_import"
  }
}

# from export buckets
resource "aws_cloudwatch_event_rule" "v3_exports" {
  for_each = toset(var.v3.services)

  name        = "${var.system}-v3_exports-${each.value}-${var.env}"
  description = each.value
  event_pattern = jsonencode({
    "detail-type" : ["Object Created"],
    "source" : ["aws.s3"],
    "detail" : {
      "bucket" : {
        "name" : ["be-${each.value}-export-${var.env}"]
      },
      "object" : {
        "key" : [{
          "prefix" : "/if/"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "v3_exports" {
  for_each = aws_cloudwatch_event_rule.v3_exports

  rule = each.value.name
  arn  = aws_sqs_queue.v3.arn

  sqs_target {
    message_group_id = each.value.description
  }
}

# v3 SQS
resource "aws_sqs_queue" "v3" {
  name                        = "${var.system}-v3-${var.env}.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perMessageGroupId"
  visibility_timeout_seconds  = 300
}

data "aws_iam_policy_document" "sqs_v3" {
  statement {
    sid    = "v3_import"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.v3.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.v3_import.arn]
    }
  }
  statement {
    sid    = "v3_exports"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.v3.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [for l in aws_cloudwatch_event_rule.v3_exports : l.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "v3" {
  queue_url = aws_sqs_queue.v3.id
  policy    = data.aws_iam_policy_document.sqs_v3.json
}

