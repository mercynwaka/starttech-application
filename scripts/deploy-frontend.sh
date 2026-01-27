#!/bin/bash
set -e

# ==========================================
# Frontend Deployment Script
# Usage: ./deploy-frontend.sh <s3-bucket-name> <cloudfront-dist-id>
# ==========================================

BUCKET_NAME=$1
DISTRIBUTION_ID=$2
BUILD_DIR="../frontend/build"

# Check for arguments
if [ -z "$BUCKET_NAME" ] || [ -z "$DISTRIBUTION_ID" ]; then
    echo "Usage: $0 <s3-bucket-name> <cloudfront-dist-id>"
    exit 1
fi

echo "--- Starting Frontend Deployment ---"

# 1. Build the React Application
echo "Step 1: Building React Application..."
cd ../frontend
# Ensure clean install
npm ci
# Build with warnings treated as non-fatal, but errors fatal
CI=false npm run build 

if [ ! -d "build" ]; then
    echo "Error: Build directory not found. Build failed."
    exit 1
fi

# 2. Sync to S3
# --delete removes files in S3 that are no longer in the build folder (keeps it clean)
echo "Step 2: Syncing build artifacts to S3: $BUCKET_NAME..."
aws s3 sync build/ s3://"$BUCKET_NAME" \
    --delete \
    --acl public-read

# 3. Invalidate CloudFront
echo "Step 3: Invalidating CloudFront Distribution: $DISTRIBUTION_ID..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

echo "Deployment Complete! Invalidation ID: $INVALIDATION_ID"
