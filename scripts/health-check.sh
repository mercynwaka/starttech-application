#!/bin/bash

# ==========================================
# Application Health Check Script
# Usage: ./health-check.sh <url> [max_retries]
# ==========================================

URL=$1
MAX_RETRIES=${2:-10}
SLEEP_TIME=10

if [ -z "$URL" ]; then
    echo "Usage: $0 <url>"
    exit 1
fi

echo "--- Starting Health Check for $URL ---"

count=0
while [ $count -lt $MAX_RETRIES ]; do
    # Curl the health endpoint, check for 200 OK status code
    # -s: Silent mode
    # -o /dev/null: discard body
    # -w "%{http_code}": print status code
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL/health")

    if [ "$HTTP_STATUS" == "200" ]; then
        echo "Success: Health check passed (HTTP 200)."
        exit 0
    fi

    echo "Attempt $(($count+1))/$MAX_RETRIES: Received HTTP $HTTP_STATUS. Retrying in $SLEEP_TIME seconds..."
    sleep $SLEEP_TIME
    count=$(($count+1))
done

echo "Error: Health check failed after $MAX_RETRIES attempts."
exit 1
