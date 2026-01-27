# Backend Rollback Script
# Usage: ./rollback.sh <asg-name> <ecr-repo-name> <previous-working-tag>

ASG_NAME=$1
ECR_REPO=$2
PREVIOUS_TAG=$3
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

if [ -z "$PREVIOUS_TAG" ]; then
    echo "Usage: $0 <asg-name> <ecr-repo-name> <previous-working-tag>"
    exit 1
fi

echo "--- Initiating Rollback to tag: $PREVIOUS_TAG ---"

# 1. Login to Docker/ECR
echo "Step 1: Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin "$REGISTRY"

# 2. Retag the previous image as 'latest'
echo "Step 2: Pulling previous image $PREVIOUS_TAG and retagging as latest..."
docker pull "$REGISTRY/$ECR_REPO:$PREVIOUS_TAG"
docker tag "$REGISTRY/$ECR_REPO:$PREVIOUS_TAG" "$REGISTRY/$ECR_REPO:latest"
docker push "$REGISTRY/$ECR_REPO:latest"

echo "Step 3: Triggering ASG Instance Refresh to pick up rollback image..."
# We call the deploy script again, as it handles the refresh logic
./deploy-backend.sh "$ASG_NAME" "$REGION"

echo "Rollback sequence initiated."
