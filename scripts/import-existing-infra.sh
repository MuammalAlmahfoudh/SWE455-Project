#!/usr/bin/env bash

set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-volleyball-api}"
API_GATEWAY_STAGE_NAME="${API_GATEWAY_STAGE_NAME:-prod}"

VPC_ID=""
IGW_ID=""
SUBNET_1_ID=""
SUBNET_2_ID=""
ROUTE_TABLE_ID=""
EC2_SG_ID=""
DB_SG_ID=""
DB_SUBNET_GROUP_NAME=""
DB_INSTANCE_ID=""
INSTANCE_ID=""
REST_API_ID=""

tf_import() {
  local address="$1"
  local id="$2"

  if [ -z "${id}" ] || [ "${id}" = "None" ]; then
    return 0
  fi

  if terraform state show "${address}" >/dev/null 2>&1; then
    return 0
  fi

  terraform import -input=false "${address}" "${id}"
}

DB_SUBNET_GROUP_NAME="$(aws rds describe-db-subnet-groups \
  --db-subnet-group-name "${PROJECT_NAME}-db-subnet-group" \
  --query 'DBSubnetGroups[0].DBSubnetGroupName' \
  --output text 2>/dev/null || true)"
DB_INSTANCE_ID="$(aws rds describe-db-instances \
  --db-instance-identifier "${PROJECT_NAME}-postgres" \
  --query 'DBInstances[0].DBInstanceIdentifier' \
  --output text 2>/dev/null || true)"

if [ -n "${DB_INSTANCE_ID}" ] && [ "${DB_INSTANCE_ID}" != "None" ]; then
  DB_SG_ID="$(aws rds describe-db-instances \
    --db-instance-identifier "${DB_INSTANCE_ID}" \
    --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
    --output text)"
  VPC_ID="$(aws ec2 describe-security-groups \
    --group-ids "${DB_SG_ID}" \
    --query 'SecurityGroups[0].VpcId' \
    --output text)"
  read -r TAGGED_SUBNET_1 TAGGED_SUBNET_2 <<< "$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=${VPC_ID}" "Name=tag:Name,Values=${PROJECT_NAME}-public-1,${PROJECT_NAME}-public-2" \
    --query 'sort_by(Subnets,&AvailabilityZone)[].SubnetId' \
    --output text 2>/dev/null || true)"

  if [ -n "${TAGGED_SUBNET_1}" ] && [ "${TAGGED_SUBNET_1}" != "None" ] && [ -n "${TAGGED_SUBNET_2}" ] && [ "${TAGGED_SUBNET_2}" != "None" ]; then
    SUBNET_1_ID="${TAGGED_SUBNET_1}"
    SUBNET_2_ID="${TAGGED_SUBNET_2}"
  else
    read -r SUBNET_1_ID SUBNET_2_ID <<< "$(aws ec2 describe-subnets \
      --filters "Name=vpc-id,Values=${VPC_ID}" \
      --query 'sort_by(Subnets,&AvailabilityZone)[].SubnetId' \
      --output text)"
  fi
  EC2_SG_ID="$(aws ec2 describe-security-groups \
    --group-ids "${DB_SG_ID}" \
    --query 'SecurityGroups[0].IpPermissions[?FromPort==`5432` && ToPort==`5432`].UserIdGroupPairs[0].GroupId | [0]' \
    --output text)"
  if [ -z "${EC2_SG_ID}" ] || [ "${EC2_SG_ID}" = "None" ]; then
    EC2_SG_ID="$(aws ec2 describe-security-groups \
      --filters "Name=vpc-id,Values=${VPC_ID}" "Name=group-name,Values=${PROJECT_NAME}-ec2-sg" \
      --query 'SecurityGroups[0].GroupId' \
      --output text)"
  fi
  ROUTE_TABLE_ID="$(aws ec2 describe-route-tables \
    --filters "Name=association.subnet-id,Values=${SUBNET_1_ID}" \
    --query 'RouteTables[0].RouteTableId' \
    --output text)"
  if [ -z "${ROUTE_TABLE_ID}" ] || [ "${ROUTE_TABLE_ID}" = "None" ]; then
    ROUTE_TABLE_ID="$(aws ec2 describe-route-tables \
      --filters "Name=association.subnet-id,Values=${SUBNET_2_ID}" \
      --query 'RouteTables[0].RouteTableId' \
      --output text)"
  fi
  if [ -z "${ROUTE_TABLE_ID}" ] || [ "${ROUTE_TABLE_ID}" = "None" ]; then
    ROUTE_TABLE_ID="$(aws ec2 describe-route-tables \
      --filters "Name=vpc-id,Values=${VPC_ID}" \
      --query 'RouteTables[?Routes[?DestinationCidrBlock==`0.0.0.0/0` && GatewayId!=null]][0].RouteTableId' \
      --output text)"
  fi
  IGW_ID="$(aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=${VPC_ID}" \
    --query 'InternetGateways[0].InternetGatewayId' \
    --output text)"
else
  VPC_ID="$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=${PROJECT_NAME}-vpc" \
    --query 'Vpcs[0].VpcId' \
    --output text)"

  if [ "${VPC_ID}" != "None" ]; then
    IGW_ID="$(aws ec2 describe-internet-gateways \
      --filters "Name=attachment.vpc-id,Values=${VPC_ID}" "Name=tag:Name,Values=${PROJECT_NAME}-igw" \
      --query 'InternetGateways[0].InternetGatewayId' \
      --output text)"
    SUBNET_1_ID="$(aws ec2 describe-subnets \
      --filters "Name=vpc-id,Values=${VPC_ID}" "Name=tag:Name,Values=${PROJECT_NAME}-public-1" \
      --query 'Subnets[0].SubnetId' \
      --output text)"
    SUBNET_2_ID="$(aws ec2 describe-subnets \
      --filters "Name=vpc-id,Values=${VPC_ID}" "Name=tag:Name,Values=${PROJECT_NAME}-public-2" \
      --query 'Subnets[0].SubnetId' \
      --output text)"
    ROUTE_TABLE_ID="$(aws ec2 describe-route-tables \
      --filters "Name=association.subnet-id,Values=${SUBNET_1_ID}" \
      --query 'RouteTables[0].RouteTableId' \
      --output text)"
    if [ -z "${ROUTE_TABLE_ID}" ] || [ "${ROUTE_TABLE_ID}" = "None" ]; then
      ROUTE_TABLE_ID="$(aws ec2 describe-route-tables \
        --filters "Name=association.subnet-id,Values=${SUBNET_2_ID}" \
        --query 'RouteTables[0].RouteTableId' \
        --output text)"
    fi
    if [ -z "${ROUTE_TABLE_ID}" ] || [ "${ROUTE_TABLE_ID}" = "None" ]; then
      ROUTE_TABLE_ID="$(aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=${VPC_ID}" "Name=tag:Name,Values=${PROJECT_NAME}-public-rt" \
        --query 'RouteTables[0].RouteTableId' \
        --output text)"
    fi
    EC2_SG_ID="$(aws ec2 describe-security-groups \
      --filters "Name=vpc-id,Values=${VPC_ID}" "Name=group-name,Values=${PROJECT_NAME}-ec2-sg" \
      --query 'SecurityGroups[0].GroupId' \
      --output text)"
    DB_SG_ID="$(aws ec2 describe-security-groups \
      --filters "Name=vpc-id,Values=${VPC_ID}" "Name=group-name,Values=${PROJECT_NAME}-db-sg" \
      --query 'SecurityGroups[0].GroupId' \
      --output text)"
  fi
fi

tf_import aws_vpc.main "${VPC_ID}"
tf_import aws_internet_gateway.main "${IGW_ID}"
tf_import 'aws_subnet.public[0]' "${SUBNET_1_ID}"
tf_import 'aws_subnet.public[1]' "${SUBNET_2_ID}"
tf_import aws_route_table.public "${ROUTE_TABLE_ID}"

if [ -n "${ROUTE_TABLE_ID}" ] && [ "${ROUTE_TABLE_ID}" != "None" ]; then
  RTA_1_ID="$(aws ec2 describe-route-tables \
    --route-table-ids "${ROUTE_TABLE_ID}" \
    --query "RouteTables[0].Associations[?SubnetId=='${SUBNET_1_ID}'].RouteTableAssociationId | [0]" \
    --output text 2>/dev/null || true)"
  RTA_2_ID="$(aws ec2 describe-route-tables \
    --route-table-ids "${ROUTE_TABLE_ID}" \
    --query "RouteTables[0].Associations[?SubnetId=='${SUBNET_2_ID}'].RouteTableAssociationId | [0]" \
    --output text 2>/dev/null || true)"

  if [ -n "${RTA_1_ID}" ] && [ "${RTA_1_ID}" != "None" ]; then
    tf_import 'aws_route_table_association.public[0]' "${SUBNET_1_ID}/${ROUTE_TABLE_ID}"
  fi

  if [ -n "${RTA_2_ID}" ] && [ "${RTA_2_ID}" != "None" ]; then
    tf_import 'aws_route_table_association.public[1]' "${SUBNET_2_ID}/${ROUTE_TABLE_ID}"
  fi
fi

tf_import aws_security_group.ec2 "${EC2_SG_ID}"
tf_import aws_security_group.db "${DB_SG_ID}"
tf_import aws_db_subnet_group.main "${DB_SUBNET_GROUP_NAME}"
tf_import aws_db_instance.postgres "${DB_INSTANCE_ID}"

INSTANCE_ID="$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${PROJECT_NAME}-app" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)"
tf_import aws_instance.app "${INSTANCE_ID}"

REST_API_ID="$(aws apigateway get-rest-apis \
  --query "items[?name=='${PROJECT_NAME}-gateway'].id | [0]" \
  --output text 2>/dev/null || true)"
tf_import aws_api_gateway_rest_api.gateway "${REST_API_ID}"

if [ -n "${REST_API_ID}" ] && [ "${REST_API_ID}" != "None" ]; then
  STAGE_NAME="$(aws apigateway get-stage \
    --rest-api-id "${REST_API_ID}" \
    --stage-name "${API_GATEWAY_STAGE_NAME}" \
    --query 'stageName' \
    --output text 2>/dev/null || true)"
  if [ -n "${STAGE_NAME}" ] && [ "${STAGE_NAME}" != "None" ]; then
    tf_import aws_api_gateway_stage.gateway "${REST_API_ID}/${STAGE_NAME}"
  fi
fi
