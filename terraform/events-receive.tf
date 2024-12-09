resource "aws_cloudwatch_event_rule" "receive" {
  for_each = var.from_receive

  name        = "${var.system}-receive-${each.value}-${var.env}"
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
          "prefix" : "${each.value}/"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "receive" {
  for_each = aws_cloudwatch_event_rule.receive

  rule = each.value.name
  arn  = aws_sqs_queue.receive.arn

  sqs_target {
    message_group_id = each.value.description
  }
}

# SQS for events
resource "aws_sqs_queue" "receive" {

  name                        = "be-${var.system}-sqs-${upper(var.env)}-01-Receive.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perMessageGroupId"
  visibility_timeout_seconds  = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 100
  })

  tags = {
    Name       = "be-${var.system}-sqs-${upper(var.env)}-01-Receive.fifo"
    SystemName = var.systemname
  }
}

data "aws_iam_policy_document" "sqs_receive" {
  statement {
    sid    = "__owner_statement"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.self.account_id}:root"]
    }

    actions   = ["SQS:*"]
    resources = [aws_sqs_queue.receive.arn]
  }
  statement {
    sid    = "receive_events"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.receive.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [for l in aws_cloudwatch_event_rule.receive : l.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "receive" {
  queue_url = aws_sqs_queue.receive.id
  policy    = data.aws_iam_policy_document.sqs_receive.json
}

resource "aws_sqs_queue" "dlq" {
  fifo_queue                  = true
  content_based_deduplication = true
  fifo_throughput_limit       = "perMessageGroupId"
  visibility_timeout_seconds  = 300

  tags = {
    Name       = "be-${var.system}-sqs-${upper(var.env)}-06-DLQ.fifo"
    SystemName = var.systemname
  }

  lifecycle {
    ignore_changes = [
      message_retention_seconds
    ]
  }
}
