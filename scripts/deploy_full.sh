#!/bin/bash
# =====================================================
# Script: deploy_full.sh
# Purpose: Automate Build → Push → ECS Deploy pipeline
# =====================================================

set -e  # Exit immediately if any command fails

# ---- CONFIGURATION ----
AWS_REGION="ap-south-1"                       # Update as per your setup
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO_NAME="my-website-repo"               # Replace with your ECR repo name
CLUSTER_NAME="ecs-web-cluster"                # Replace with your ECS cluster name
SERVICE_NAME="ecs-web-service"                # Replace with your ECS service name
IMAGE_TAG=${1:-"latest"}                      # Optional: pass a version tag
ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

echo "============================================================="
echo "🚀 Starting Full Deployment Process"
echo "AWS Region    : ${AWS_REGION}"
echo "ECR Repository: ${ECR_REPO_NAME}"
echo "ECS Cluster   : ${CLUSTER_NAME}"
echo "ECS Service   : ${SERVICE_NAME}"
echo "Image Tag     : ${IMAGE_TAG}"
echo "============================================================="

# ---- STEP 1: Build and push Docker image to ECR ----
echo "[1/3] Building and pushing Docker image to ECR..."
chmod +x scripts/build_and_push_ecr.sh
./scripts/build_and_push_ecr.sh ${IMAGE_TAG}

# ---- STEP 2: Update ECS service with new image ----
echo "[2/3] Updating ECS service with new task definition..."
chmod +x scripts/ecs_deploy.sh
./scripts/ecs_deploy.sh ${IMAGE_TAG}

# ---- STEP 3: Verify ECS Deployment ----
echo "[3/3] Verifying ECS service status..."
aws ecs describe-services \
  --cluster ${CLUSTER_NAME} \
  --services ${SERVICE_NAME} \
  --region ${AWS_REGION} \
  --query "services[0].deployments" \
  --output table

echo "============================================================="
echo "✅ Deployment completed successfully!"
echo "ECR Image: ${ECR_URL}:${IMAGE_TAG}"
echo "============================================================="