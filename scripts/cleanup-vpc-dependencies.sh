#!/usr/bin/env bash

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="${PROJECT_NAME:-volleyball-api}"

find_vpc_id() {
  aws ec2 describe-vpcs \
    --region "${AWS_REGION}" \
    --filters "Name=tag:Name,Values=${PROJECT_NAME}-vpc" \
    --query 'Vpcs[0].VpcId' \
    --output text 2>/dev/null || true
}

VPC_ID="$(find_vpc_id)"

if [ -z "${VPC_ID}" ] || [ "${VPC_ID}" = "None" ]; then
  echo "No tagged project VPC found. Nothing to clean up."
  exit 0
fi

echo "Cleaning up lingering VPC dependencies for ${VPC_ID}"

echo "Remaining network interfaces:"
aws ec2 describe-network-interfaces \
  --region "${AWS_REGION}" \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'NetworkInterfaces[].{Id:NetworkInterfaceId,Status:Status,RequesterManaged:RequesterManaged,Attachment:Attachment.AttachmentId,Description:Description,Subnet:SubnetId}' \
  --output table || true

for attachment_id in $(aws ec2 describe-network-interfaces \
  --region "${AWS_REGION}" \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'NetworkInterfaces[?Attachment.AttachmentId!=null && RequesterManaged==`false`].Attachment.AttachmentId' \
  --output text 2>/dev/null || true); do
  if [ -n "${attachment_id}" ] && [ "${attachment_id}" != "None" ]; then
    echo "Force-detaching network interface attachment ${attachment_id}"
    aws ec2 detach-network-interface \
      --region "${AWS_REGION}" \
      --attachment-id "${attachment_id}" \
      --force || true
  fi
done

sleep 15

for eni_id in $(aws ec2 describe-network-interfaces \
  --region "${AWS_REGION}" \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'NetworkInterfaces[?Status==`available` && RequesterManaged==`false`].NetworkInterfaceId' \
  --output text 2>/dev/null || true); do
  if [ -n "${eni_id}" ] && [ "${eni_id}" != "None" ]; then
    echo "Deleting available network interface ${eni_id}"
    aws ec2 delete-network-interface \
      --region "${AWS_REGION}" \
      --network-interface-id "${eni_id}" || true
  fi
done

for igw_id in $(aws ec2 describe-internet-gateways \
  --region "${AWS_REGION}" \
  --filters "Name=attachment.vpc-id,Values=${VPC_ID}" \
  --query 'InternetGateways[].InternetGatewayId' \
  --output text 2>/dev/null || true); do
  if [ -n "${igw_id}" ] && [ "${igw_id}" != "None" ]; then
    echo "Detaching and deleting internet gateway ${igw_id}"
    aws ec2 detach-internet-gateway \
      --region "${AWS_REGION}" \
      --internet-gateway-id "${igw_id}" \
      --vpc-id "${VPC_ID}" || true
    aws ec2 delete-internet-gateway \
      --region "${AWS_REGION}" \
      --internet-gateway-id "${igw_id}" || true
  fi
done

for assoc_id in $(aws ec2 describe-route-tables \
  --region "${AWS_REGION}" \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'RouteTables[].Associations[?Main==`false` && RouteTableAssociationId!=null].RouteTableAssociationId' \
  --output text 2>/dev/null || true); do
  if [ -n "${assoc_id}" ] && [ "${assoc_id}" != "None" ]; then
    echo "Disassociating route table association ${assoc_id}"
    aws ec2 disassociate-route-table \
      --region "${AWS_REGION}" \
      --association-id "${assoc_id}" || true
  fi
done

for rtb_id in $(aws ec2 describe-route-tables \
  --region "${AWS_REGION}" \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'RouteTables[?length(Associations[?Main==`true`])==`0`].RouteTableId' \
  --output text 2>/dev/null || true); do
  if [ -n "${rtb_id}" ] && [ "${rtb_id}" != "None" ]; then
    echo "Deleting non-main route table ${rtb_id}"
    aws ec2 delete-route-table \
      --region "${AWS_REGION}" \
      --route-table-id "${rtb_id}" || true
  fi
done

for subnet_id in $(aws ec2 describe-subnets \
  --region "${AWS_REGION}" \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'Subnets[].SubnetId' \
  --output text 2>/dev/null || true); do
  if [ -n "${subnet_id}" ] && [ "${subnet_id}" != "None" ]; then
    echo "Deleting subnet ${subnet_id}"
    aws ec2 delete-subnet \
      --region "${AWS_REGION}" \
      --subnet-id "${subnet_id}" || true
  fi
done

for sg_id in $(aws ec2 describe-security-groups \
  --region "${AWS_REGION}" \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
  --output text 2>/dev/null || true); do
  if [ -n "${sg_id}" ] && [ "${sg_id}" != "None" ]; then
    echo "Deleting non-default security group ${sg_id}"
    aws ec2 delete-security-group \
      --region "${AWS_REGION}" \
      --group-id "${sg_id}" || true
  fi
done

echo "Attempting direct VPC delete for ${VPC_ID}"
aws ec2 delete-vpc \
  --region "${AWS_REGION}" \
  --vpc-id "${VPC_ID}" || true

VPC_ID="$(find_vpc_id)"
if [ -n "${VPC_ID}" ] && [ "${VPC_ID}" != "None" ]; then
  echo "VPC ${VPC_ID} still exists after cleanup. Remaining blockers:"

  aws ec2 describe-network-interfaces \
    --region "${AWS_REGION}" \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --query 'NetworkInterfaces[].{Id:NetworkInterfaceId,Status:Status,RequesterManaged:RequesterManaged,Attachment:Attachment.AttachmentId,Description:Description,Subnet:SubnetId}' \
    --output table || true

  aws ec2 describe-route-tables \
    --region "${AWS_REGION}" \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --query 'RouteTables[].{Id:RouteTableId,Associations:Associations}' \
    --output table || true

  aws ec2 describe-subnets \
    --region "${AWS_REGION}" \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --query 'Subnets[].{Id:SubnetId,Az:AvailabilityZone,Cidr:CidrBlock}' \
    --output table || true

  aws ec2 describe-security-groups \
    --region "${AWS_REGION}" \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --query 'SecurityGroups[].{Id:GroupId,Name:GroupName}' \
    --output table || true
else
  echo "VPC cleanup succeeded."
fi
