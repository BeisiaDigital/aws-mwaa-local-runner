# transfer from export buckets
resource "aws_cloudwatch_event_rule" "put_sinops" {
  name        = "${var.system}-put_sinops-${var.env}"
  description = "put sinops"
  event_pattern = jsonencode({
    "detail-type" : ["Object Created"],
    "source" : ["aws.s3"],
    "detail" : {
      "bucket" : {
        "name" : ["be-sinops-import-${var.env}"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "put_sinops" {
  rule = aws_cloudwatch_event_rule.put_sinops.name
  arn  = aws_sqs_queue.put_sinops.arn

  sqs_target {
    message_group_id = "put_sinops"
  }
}

resource "aws_sqs_queue" "put_sinops" {
  name                        = "${var.system}-put_sinops-${var.env}.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perMessageGroupId"
  visibility_timeout_seconds  = 300
}

data "aws_iam_policy_document" "sqs_put_sinops" {
  statement {
    sid    = "__owner_statement"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.self.account_id}:root"]
    }

    actions   = ["SQS:*"]
    resources = [aws_sqs_queue.put_sinops.arn]
  }
  statement {
    sid    = "put_sinops"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.put_sinops.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.put_sinops.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "put_sinops" {
  queue_url = aws_sqs_queue.put_sinops.id
  policy    = data.aws_iam_policy_document.sqs_put_sinops.json
}
