#!/bin/bash

# ==========================================
# Improved Application Health Check Script
# ==========================================

URL=$1
MAX_RETRIES=${2:-15}  # Increased retries for slower AWS boots
SLEEP_TIME=15         # Increased interval to allow for image pulls

if [ -z "$URL" ]; then
    echo "Usage: $0 <url>"
    exit 1
fi

echo "--- Starting Resilient Health Check for $URL ---"
echo "Giving the infrastructure 30 seconds to initialize before first check..."
sleep 30 

count=0
while [ $count -lt $MAX_RETRIES ]; do
    # -L: Follow redirects if the ALB uses them
    # --retry 3: Internal curl retry for network blips
    # --connect-timeout 5: Don't hang on broken connections
    HTTP_STATUS=$(curl -s -L -o /dev/null --connect-timeout 5 --retry 3 -w "%{http_code}" "$URL/health")

    if [ "$HTTP_STATUS" == "200" ]; then
        echo "✅ Success: Health check passed (HTTP 200) on attempt $(($count+1))."
        exit 0
    fi
    
    # Check for 502/503/504 which are common during container startup
    echo "⚠️ Attempt $(($count+1))/$MAX_RETRIES: Received HTTP $HTTP_STATUS. (App still starting?)"
    echo "Retrying in $SLEEP_TIME seconds..."
    
    sleep $SLEEP_TIME
    count=$(($count+1))
done

echo "❌ Error: Health check failed after $MAX_RETRIES attempts. Check AWS Target Group logs."
exit 1
