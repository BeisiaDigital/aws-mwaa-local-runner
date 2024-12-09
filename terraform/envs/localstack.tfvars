profile    = "localstack"
region     = "ap-northeast-1"
env        = "dev"
system     = "kif"
systemname = "Digital Interface Platform"

# buket policy
receive-policy = "./bucket_policy/dev_receive.json"
send-policy    = "./bucket_policy/dev_send.json"

# kms
kms-kif = "./kms/dev_kms-kif.json"

# bucket
bucket = {
  receive = {
    expire = 7
  }
  storage = {
    expire = 9
  }
}

vpc_id          = "vpc-00e5cbb7e223eb039"
subnet_ids      = ["subnet-0b93366c87976d23c", "subnet-03ebf470dba4f3b2f"]
vpce_subnet_ids = ["subnet-0d426acbaffbbc4e9", "subnet-04bfa9f9fe2f48f85"]

SSO = {
  AdministratorRole   = "role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_a3e70e67192ccfd8"
  BeAdministratorRole = "role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_be_Administrator_727cee6f5a1f1fe7"
}

# trocco
trocco_eid = "0bf9fa09-7682-4883-b1bc-9256c2888624"

# relayship
relayshipv2 = {
  bgprd_xinvoke_role = "arn:aws:iam::938772071201:role/IAMRole-Lambda-yzrly-XInvokeFunc-ver2"
  yzrly_lambda_name  = "arn:aws:lambda:ap-northeast-1:938772071201:function:BG-yzrly-DEV-EventWriter-ver2"
}

relayshipv3 = {
  lambda   = ""
  eventbus = ""
}

# mwaa
mwaa = {
  log_level = "INFO"
  blue = {
    class   = "mw1.small"
    version = "2.9.2"
  }
  green = {
    class   = "mw1.small"
    version = "2.7.2"
  }
}

transfer_aids = [
  "335288808572", # pig dev
  "654654424865"  # stores dev
]

transfer_receive = [
  "bsintdb",
  "sagent",
  "bzh",
  "be_mex",
  "bd_account",
  "bes",
  "eob",
  "b_retail",
  "cjk",
  "ebase",
  "gks"
]

transfer_exports = [
  "iip",
  "bml",
  "sinops",
  "prs",
  "was"
]

from_receive = [
  # 次期POS
  "be_mex_ar_ad",
  "be_mex_be_account",
  "be_mex_be_ar_system",
  "be_mex_c_pos",
  "be_mex_cpm",
  "be_mex_inventory_real",
  "be_mex_new_eob",
  "be_mex_new_point",
  "be_mex_hap136ia",
  "be_mex_penta_senser",
  "be_mex_s_rank",
  "b_retail_be_mex",
  "mcb_be_mex",
  "new_eob_be_mex",
  "penta_senser_be_mex",
  # 次期POS CZ
  "be_mex_esl_system",
  "b_retail_cz_mex",
  "cz_mex_b_retail",
  "cz_mex_be_account",
  "cz_mex_esl_system",
  "cz_mex_inventory_real",
  "cz_mex_new_eob",
  "c_pos_be_mex",
  "new_eob_cz_mex",
  "service_cloud_be_mex"
]

to_relayshipv2 = [
  # 次期POS
  "be_mex_ar_ad",
  "be_mex_be_account",
  "be_mex_be_ar_system",
  "be_mex_b_retail",
  "be_mex_c_pos",
  "be_mex_hap136ia",
  "be_mex_inventory_real",
  "be_mex_new_eob",
  "be_mex_new_point",
  "be_mex_penta_senser",
  "be_mex_regisuke",
  "be_mex_s_rank",
  "b_retail_be_mex",
  "mcb_be_mex",
  "new_eob_be_mex",
  "penta_senser_be_mex",
  # 次期POS CZ
  "service_cloud_be_mex",
  "b_retail_cz_mex",
  "cz_mex_b_retail",
  "cz_mex_be_account",
  "cz_mex_esl_system",
  "cz_mex_inventory_real",
  "cz_mex_new_eob",
  "cz_mex_penta_senser",
  "c_pos_be_mex",
  "new_eob_cz_mex",
  "service_cloud_be_mex",
  # 生鮮棚卸し
  "fir-bes",
  # 店内消耗
  "iip-bes",
  "iip-bzh",
  # POS稼働
  "be_mex-bd_account",
  # bmail
  "bml-bsintdb",
  "bml-eob",
  # sinops
  "sinops-eob"
]

# DEVにRSv3が存在しないため、常に空setとする
to_relayshipv3 = []

# container
containers = {
  receive = {
  }
  get_rns_order = {
    cpu    = 512
    memory = 2048
  }
  get_rns_cancel = {
    cpu    = 512
    memory = 2048
  }
  get_rec = {
    cpu    = 512
    memory = 2048

  }
  get_yec = {
    cpu    = 512
    memory = 2048
  }
}

email_domain = "be.dev-bgcloud.jp"

prober_sso_roleid = [
  "AROA6BMYR7VKKXQ744UXQ",
  "AROA6BMYR7VKIYSMBIB7A"
]

log = {
  retention = 14
}

pd_endpoint = ""

# v3構築時に必要な設定。v3開発一時停止なので一時的にコメントアウト
# v3 = {
#   services = [
#     "sinops"
#   ]
# }
# vpc endpoint source ips
vpce_source_ips = {
  eob      = []
  b-retail = []
  bsintdb  = []
}
