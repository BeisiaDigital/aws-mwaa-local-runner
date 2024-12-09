# aws
variable "profile" {}
variable "region" {}

# Common
variable "env" {}
variable "system" {}
variable "systemname" {}

# buckets policy
variable "receive-policy" {}
variable "send-policy" {}

# kms
variable "kms-kif" {}

# bucket
variable "bucket" {}

variable "vpc_id" {}
variable "subnet_ids" {}
variable "vpce_subnet_ids" {}
variable "SSO" {}

# trocco
variable "trocco_eid" {}

# relayship
variable "relayshipv2" {
  type = map(string)
}

variable "relayshipv3" {}

variable "mwaa" {}

# account ids from cross account transfer
variable "transfer_aids" {}

# eventbrige rules
variable "from_receive" {
  type = set(string)
}
variable "transfer_receive" {
  type = set(string)
}
variable "transfer_exports" {
  type = set(string)
}
variable "to_relayshipv2" {
  type = set(string)
}

variable "to_relayshipv3" {
  type = set(string)
}

# container
variable "containers" {
  type = map(object({
    cpu           = optional(number, 256)
    memory        = optional(number, 2048)
    log_retention = optional(number, 14)
    image_version = optional(string, "latest")
  }))
}

variable "email_domain" {}

# prober
variable "prober_sso_roleid" {}

variable "log" {}

# sns
variable "pd_endpoint" {}

# # v3
# variable "v3" {}

# vpc_endpoint
variable "vpce_source_ips" {} # 許可するホストのIPアドレスを指定
