locals {
  deployment_az = ["ap-northeast-1a", "ap-northeast-1c"]
}

data "aws_caller_identity" "self" {}

# # BGS作成policyなのでdata sourceで取得
# data "aws_vpc" "main" {
#   id = var.vpc_id
# }
# data "aws_subnet" "priL" {
#   count             = 2
#   availability_zone = element(local.deployment_az, count.index + 1)
#   vpc_id            = var.vpc_id

#   filter {
#     name   = "subnet-id"
#     values = var.subnet_ids
#   }
# }

# # TODO: import bucketはaws-account-beからこのrepoに移動する
# data "aws_s3_bucket" "import" {
#   bucket = "be-kif-import-${var.env}"
# }

# dlk_aws-infraで管理しているのでdata sourceで取得
data "aws_s3_bucket" "dlk" {
  bucket = "be-dlk-${var.env}"
}

# # aws-account-beで管理しているのでdata sourceで取得　
# data "aws_sesv2_email_identity" "public" {
#   email_identity = var.email_domain
# }
# data "aws_sesv2_configuration_set" "public" {
#   configuration_set_name = replace(var.email_domain, ".", "_")
# }

# # BGS作成policyなのでdata sourceで取得
# data "aws_iam_role" "relayshipv3" {
#   name = "IAMRole-Events-PutEvents"
# }

# AWS managed resources
data "aws_cloudwatch_event_bus" "default" {
  name = "default"
}
data "aws_iam_policy" "AmazonECSTaskExecutionRolePolicy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
data "aws_iam_policy" "CloudWatchReadOnlyAccess" {
  arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}
data "aws_iam_policy" "CloudWatchLogsReadOnlyAccess" {
  arn = "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
}

# data "aws_iam_openid_connect_provider" "github_oidc_provider" {
#   arn = "arn:aws:iam::${data.aws_caller_identity.self.account_id}:oidc-provider/token.actions.githubusercontent.com"
# }
