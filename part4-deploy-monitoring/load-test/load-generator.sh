#!/bin/bash

# Simple load generator for backend API
# Usage: ./load-generator.sh [URL] [REQUESTS] [CONCURRENCY]

URL=${1:-http://$(minikube ip):30001/api}
REQUESTS=${2:-1000}
CONCURRENCY=${3:-10}

echo "Generating load: $REQUESTS requests, $CONCURRENCY concurrent"
echo "Target URL: $URL"

# Install hey if not available
if ! command -v hey &> /dev/null; then
    echo "Installing hey load testing tool..."
    go get -u github.com/rakyll/hey
fi

# Run load test
hey -n $REQUESTS -c $CONCURRENCY $URL

