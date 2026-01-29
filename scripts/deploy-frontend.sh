#!/bin/bash
set -e

# ==========================================
# Frontend Deployment Script
# Usage: ./scripts/deploy-frontend.sh <s3-bucket-name> <cloudfront-dist-id>
# ==========================================

BUCKET_NAME=$1
DISTRIBUTION_ID=$2

# Since GitHub Actions runs from the ROOT, we point directly to the folder
BUILD_DIR="./frontend/build"

# Check for arguments
if [ -z "$BUCKET_NAME" ] || [ -z "$DISTRIBUTION_ID" ]; then
    echo "Usage: $0 <s3-bucket-name> <cloudfront-dist-id>"
    exit 1
fi

echo "--- Starting Frontend Deployment ---"

# Pre-check: Verify the build actually exists
# (This ensures the YAML 'npm run build' step succeeded)
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory '$BUILD_DIR' not found."
    echo "Ensure your YAML file runs 'npm run build' BEFORE calling this script."
    exit 1
fi

# 1. Sync to S3
# Note: REMOVED '--acl public-read' because your bucket blocks public ACLs (Security Best Practice)
echo "Step 1: Syncing build artifacts to S3: $BUCKET_NAME..."
aws s3 sync "$BUILD_DIR" s3://"$BUCKET_NAME" --delete

# 2. Invalidate CloudFront
echo "Step 2: Invalidating CloudFront Distribution: $DISTRIBUTION_ID..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

echo "Deployment Complete! Invalidation ID: $INVALIDATION_ID"
