#!/bin/bash
set -e

# ==========================================
# Backend Deployment Script
# Usage: ./deploy-backend.sh <asg-name> <region>
# ==========================================

ASG_NAME=$1
REGION=${2:-us-east-1}

if [ -z "$ASG_NAME" ]; then
    echo "Usage: $0 <asg-name> [region]"
    exit 1
fi

echo "--- Starting Backend Rolling Deployment ---"

# 1. Start Instance Refresh
# MinHealthyPercentage=50 ensures we always have half our capacity up during deploy
echo "Step 1: Triggering Instance Refresh on ASG: $ASG_NAME..."
REFRESH_ID=$(aws autoscaling start-instance-refresh \
    --auto-scaling-group-name "$ASG_NAME" \
    --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 60}' \
    --region "$REGION" \
    --query 'InstanceRefreshId' \
    --output text)

echo "Instance Refresh started with ID: $REFRESH_ID"

# 2. Watch for Completion (Optional but recommended for CI/CD)
echo "Step 2: Waiting for deployment to complete..."
while true; do
    STATUS=$(aws autoscaling describe-instance-refreshes \
        --auto-scaling-group-name "$ASG_NAME" \
        --instance-refresh-ids "$REFRESH_ID" \
        --region "$REGION" \
        --query 'InstanceRefreshes[0].Status' \
        --output text)

    echo "Current Status: $STATUS"

    if [ "$STATUS" == "Successful" ]; then
        echo "Deployment Successful!"
        exit 0
    elif [ "$STATUS" == "Failed" ] || [ "$STATUS" == "Cancelled" ]; then
        echo "Deployment Failed or Cancelled."
        exit 1
    fi

    sleep 30
done
