#!/bin/bash
# =====================================================
# Script: build_and_push_ecr.sh
# Purpose: Build and push Docker image to AWS ECR
# =====================================================

set -e  # Exit on error

# ---- Configuration ----
AWS_REGION="ap-south-1"                # Update region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO_NAME="my-website-repo"        # Replace with your repo name
IMAGE_TAG=${1:-latest}                 # Allow optional image tag, defaults to 'latest'

# ---- Build Variables ----
ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

echo "=============================================="
echo " Building and pushing image to ECR "
echo " Repository : ${ECR_REPO_NAME}"
echo " Image Tag  : ${IMAGE_TAG}"
echo "=============================================="

# ---- Login to ECR ----
echo "[1/4] Logging in to Amazon ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# ---- Build Docker image ----
echo "[2/4] Building Docker image..."
docker build -t ${ECR_REPO_NAME}:${IMAGE_TAG} .

# ---- Tag the image ----
echo "[3/4] Tagging image..."
docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${ECR_URL}:${IMAGE_TAG}

# ---- Push to ECR ----
echo "[4/4] Pushing image to ECR..."
docker push ${ECR_URL}:${IMAGE_TAG}

echo "✅ Image successfully pushed to: ${ECR_URL}:${IMAGE_TAG}"