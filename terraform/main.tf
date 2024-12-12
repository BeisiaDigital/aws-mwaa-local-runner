#
# main.tf
#
terraform {
  required_version = "~> 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.37.0"
    }
  }
  backend "s3" {}

}
provider "aws" {
  region  = "ap-northeast-1"
  profile = "localstack"

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "http://localstack:4566"
  }
}
