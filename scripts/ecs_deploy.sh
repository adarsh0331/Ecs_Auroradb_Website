#!/bin/bash
# =====================================================
# Script: ecs_deploy.sh
# Purpose: Update ECS Service with new image version
# =====================================================

set -e  # Exit on error

# ---- Configuration ----
AWS_REGION="ap-south-1"                      # Update region
CLUSTER_NAME="ecs-web-cluster"               # Replace with your ECS cluster name
SERVICE_NAME="ecs-web-service"               # Replace with your ECS service name
ECR_REPO_NAME="my-website-repo"              # Replace with your ECR repo name
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE_TAG=${1:-latest}

ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}"

echo "=============================================="
echo " Deploying ECS Service Update "
echo " Cluster : ${CLUSTER_NAME}"
echo " Service : ${SERVICE_NAME}"
echo " New Image: ${ECR_URL}"
echo "=============================================="

# ---- Get current task definition ----
TASK_DEF=$(aws ecs describe-services \
  --cluster ${CLUSTER_NAME} \
  --services ${SERVICE_NAME} \
  --query "services[0].taskDefinition" \
  --output text)

# ---- Create new task definition revision ----
NEW_TASK_DEF_JSON=$(aws ecs describe-task-definition \
  --task-definition ${TASK_DEF} \
  --query "taskDefinition" \
  | jq --arg IMAGE "${ECR_URL}" '.containerDefinitions[0].image = $IMAGE | del(.status, .revision, .taskDefinitionArn, .requiresAttributes, .compatibilities)')

NEW_TASK_DEF_ARN=$(echo ${NEW_TASK_DEF_JSON} | \
  aws ecs register-tas