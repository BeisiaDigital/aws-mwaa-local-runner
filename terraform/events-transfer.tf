# transfer from recieve
resource "aws_cloudwatch_event_rule" "transfer_receive" {
  for_each = var.transfer_receive

  name        = "${var.system}-transfer_receive-${each.value}-${var.env}"
  description = each.value
  event_pattern = jsonencode({
    "detail-type" : ["Object Created"],
    "source" : ["aws.s3"],
    "detail" : {
      "bucket" : {
        "name" : [aws_s3_bucket.receive.bucket]
      },
      "object" : {
        "key" : [{
          "prefix" : "${each.value}-"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "transfer_receive" {
  for_each = aws_cloudwatch_event_rule.transfer_receive

  rule = each.value.name
  arn  = aws_sqs_queue.transfer.arn

  sqs_target {
    message_group_id = each.value.description
  }
}

# transfer from export buckets
resource "aws_cloudwatch_event_rule" "transfer_exports" {
  for_each = var.transfer_exports

  name        = "${var.system}-transfer_exports-${each.value}-${var.env}"
  description = each.value
  event_pattern = jsonencode({
    "detail-type" : ["Object Created"],
    "source" : ["aws.s3"],
    "detail" : {
      "bucket" : {
        "name" : ["be-${each.value}-export-${var.env}"]
        # v3構築時に必要な設定。v3開発一時停止なので一時的にコメントアウト
        # },
        # "object" : {
        #   "key" : [{
        #     "prefix" : "${each.value}-"
        #   }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "transfer_exports" {
  for_each = aws_cloudwatch_event_rule.transfer_exports

  rule = each.value.name
  arn  = aws_sqs_queue.transfer.arn

  sqs_target {
    message_group_id = each.value.description
  }
}


# TODO: v3でも使っているリソースなので、ファイルを分ける
data "aws_iam_policy_document" "eventbus_default_policy" {
  statement {
    sid    = "CrossAccountTransfer"
    effect = "Allow"
    actions = [
      "events:PutEvents",
    ]
    resources = [
      data.aws_cloudwatch_event_bus.default.arn
    ]

    principals {
      type        = "AWS"
      identifiers = var.transfer_aids
    }
  }
}

# TODO: v3でも使っているリソースなので、ファイルを分ける
resource "aws_cloudwatch_event_bus_policy" "default" {
  policy         = data.aws_iam_policy_document.eventbus_default_policy.json
  event_bus_name = data.aws_cloudwatch_event_bus.default.name
}

# SQS for events
resource "aws_sqs_queue" "transfer" {
  name                        = "${var.system}-transfer-${var.env}.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perMessageGroupId"
  visibility_timeout_seconds  = 300
}

data "aws_iam_policy_document" "sqs_transfer" {
  statement {
    sid    = "__owner_statement"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.self.account_id}:root"]
    }

    actions   = ["SQS:*"]
    resources = [aws_sqs_queue.transfer.arn]
  }
  statement {
    sid    = "transfer_receive"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.transfer.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [for l in aws_cloudwatch_event_rule.transfer_receive : l.arn]
    }
  }
  statement {
    sid    = "transfer_exports"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.transfer.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [for l in aws_cloudwatch_event_rule.transfer_exports : l.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "transfer" {
  queue_url = aws_sqs_queue.transfer.id
  policy    = data.aws_iam_policy_document.sqs_transfer.json
}
