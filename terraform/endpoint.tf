# #
# # b-retail向けonprem_s3_gateway
# #
# module "s3_gateway" {
#   for_each = var.vpce_source_ips

#   source = "./modules/s3_gateway"
#   env    = var.env
#   source_system = {
#     name = each.key
#     ips  = each.value
#   }
#   vpc_id     = data.aws_vpc.main.id
#   subnet_ids = var.vpce_subnet_ids
# }
data "aws_iam_policy_document" "import-vpces" {
  for_each = var.vpce_source_ips

  statement {
    sid = "${each.key}_getput"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:PutObject",
      "s3:Get*",
    ]
    resources = [
      "${aws_s3_bucket.import.arn}/${each.key}/if/*",
    ]
    # condition {
    #   test     = "StringEquals"
    #   variable = "aws:SourceVpce"
    #   values   = [module.s3_gateway["${each.key}"].endpoint_id]
    # }
  }
  statement {
    sid = "${each.key}_list"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.import.arn
    ]

    # condition {
    #   test     = "StringEquals"
    #   variable = "aws:SourceVpce"
    #   values   = [module.s3_gateway["${each.key}"].endpoint_id]
    # }

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${each.key}/if/*"]
    }
  }
}


# b-retail向け*-pf/*へのアクセスを許可設定i, */if/*に移行後削除
data "aws_iam_policy_document" "bretail-access" {
  statement {
    sid = "b-retail"
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject",
      "s3:Get*",
    ]

    resources = [
      "${aws_s3_bucket.import.arn}/b_retail-pf/*",
    ]

    # condition {
    #   test     = "StringEquals"
    #   variable = "aws:SourceVpce"
    #   values   = [module.s3_gateway["b-retail"].endpoint_id]
    # }
  }
  statement {
    sid = "listobjects_b-retail"
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.import.arn
    ]

    # condition {
    #   test     = "StringEquals"
    #   variable = "aws:SourceVpce"
    #   values   = [module.s3_gateway["b-retail"].endpoint_id]
    # }

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["b_retail-pf/*"]
    }
  }
}

# eob向け*-pf/*へのアクセスを許可設定, */if/*に移行後削除
data "aws_iam_policy_document" "eob-access" {
  statement {
    sid = "eob"
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject",
      "s3:Get*",
    ]

    resources = [
      "${aws_s3_bucket.import.arn}/eob-pf/*",
    ]

    # condition {
    #   test     = "StringEquals"
    #   variable = "aws:SourceVpce"
    #   values   = [module.s3_gateway["eob"].endpoint_id]
    # }
  }
  statement {
    sid = "listobjects_eob"
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.import.arn
    ]

    # condition {
    #   test     = "StringEquals"
    #   variable = "aws:SourceVpce"
    #   values   = [module.s3_gateway["eob"].endpoint_id]
    # }

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["eob-pf/*"]
    }
  }
}
