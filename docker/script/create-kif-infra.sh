#!/bin/sh
#
# kif-infraリポジトリ管理外のインフラを構築するコマンド
#
#######################

ENDPOINT="http://localstack:4566"
TF="be-s3-terraform-localstack"
V1_CONF="be-s3-kif-order-dev"
V2_CONF="be-kif-dag-dev"
BUCKETS="be-dlk-dev be-mock-sinops be-sinops-export-dev be-iip-import-dev be-iip-export-dev be-bml-export-dev be-bml-import-dev be-sinops-import-dev"

# create terraform backend bucket
aws --profile localstack s3 mb s3://${TF} --endpoint ${ENDPOINT}

# create order (receive config) bucket (order bucket is not managed kif-infra repository)
aws --profile localstack s3 mb s3://${V1_CONF} --endpoint ${ENDPOINT}
aws --profile localstack s3 cp /root/conf/MBBBUN.yaml s3://${V1_CONF}/b_retail_be_mex/Conf/MBBBUN.yaml  --endpoint ${ENDPOINT}
aws --profile localstack s3 cp /root/conf/SPAL_Z.yaml s3://${V1_CONF}/be_mex_inventory_real/Conf/SPAL_Z.yaml  --endpoint ${ENDPOINT}

# upload v2 conf
aws --profile localstack s3 mb s3://${V2_CONF} --endpoint ${ENDPOINT}
aws --profile localstack s3 cp /root/conf s3://${V2_CONF}/conf  --endpoint ${ENDPOINT} --recursive

# other bucket
for bucket in ${BUCKETS} ; do 
    aws --profile localstack s3 mb s3://${bucket} --endpoint ${ENDPOINT}
    aws --profile localstack s3api put-bucket-versioning --bucket ${bucket} --versioning-configuration Status=Enabled --endpoint ${ENDPOINT}
done

# create test role
aws --profile localstack iam create-role --role-name kif-prober-local --assume-role-policy-document '{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Principal\": {\"AWS\": \"*\"}, \"Action\": \"sts:AssumeRole\"}]}' --endpoint ${ENDPOINT}
aws --profile localstack iam attach-role-policy --role-name kif-prober-local --policy-arn arn:aws:iam::aws:policy/PowerUserAccess --endpoint ${ENDPOINT}

# これがないと戻り値が255になってしまい正常終了と見なされず、terraformコンテナが起動しない
exit 0