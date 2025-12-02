#!/bin/bash

set -e

NETWORK=$1
IMPLEMENTATION=$2
PROXY=$3
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ -z "$NETWORK" ] || [ -z "$IMPLEMENTATION" ] || [ -z "$PROXY" ]; then
    echo "Usage: $0 <network> <implementation> <proxy>"
    exit 1
fi

DEPLOYMENT_DIR="deployments/v1"
mkdir -p "$DEPLOYMENT_DIR"

DEPLOYMENT_FILE="$DEPLOYMENT_DIR/$NETWORK.json"

cat > "$DEPLOYMENT_FILE" << EOF
{
  "network": "$NETWORK",
  "chainId": "$(cast chain-id)",
  "deploymentDate": "$TIMESTAMP",
  "contracts": {
    "LoopTemplateV1Implementation": "$IMPLEMENTATION",
    "LoopTemplateV1Proxy": "$PROXY"
  }
}
EOF

echo "Deployment info saved to $DEPLOYMENT_FILE"
cat "$DEPLOYMENT_FILE"
