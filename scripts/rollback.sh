#!/bin/bash
set -e

# Usage: ./scripts/rollback.sh <asg-name> <ecr-repo-name> <previous-working-tag>

# 1. Read Arguments
export ASG_NAME=$1
ECR_REPO=$2
PREVIOUS_TAG=$3
export AWS_REGION="us-east-1" # Ensure deploy script sees this too

if [ -z "$PREVIOUS_TAG" ]; then
    echo "Usage: $0 <asg-name> <ecr-repo-name> <previous-working-tag>"
    exit 1
fi

echo "--- Initiating Rollback for $ECR_REPO to tag: $PREVIOUS_TAG ---"

# 2. Retag in ECR (The Fast Way - No Docker Pull needed!)
echo "Step 1: Retagging '$PREVIOUS_TAG' as 'latest' via AWS CLI..."

# Get the image manifest of the working tag
MANIFEST=$(aws ecr batch-get-image --repository-name $ECR_REPO \
    --image-ids imageTag=$PREVIOUS_TAG \
    --region $AWS_REGION \
    --query 'images[].imageManifest' \
    --output text)

if [ -z "$MANIFEST" ]; then
    echo "Error: Could not find image with tag $PREVIOUS_TAG in repo $ECR_REPO"
    exit 1
fi


aws ecr batch-delete-image --repository-name $ECR_REPO --image-ids imageTag=latest --region $AWS_REGION || true
aws ecr put-image --repository-name $ECR_REPO --image-tag latest --image-manifest "$MANIFEST" --region $AWS_REGION

echo "Image retagged successfully."

# 3. Trigger Instance Refresh
echo "Step 2: Triggering ASG Instance Refresh..."
# We export ASG_NAME above so the script picks it up automatically
./scripts/deploy-backend.sh

echo "Rollback initiated. Monitor the ASG console for progress."
