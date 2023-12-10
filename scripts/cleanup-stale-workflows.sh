#!/bin/bash

# Replace these variables
GITHUB_TOKEN="2a1bf6cxxxxxxxx"
OWNER="meetearnest"
REPO="infra-secrets"

# List of run IDs
# gh run list --workflow="v2 Sops Publish" --json databaseId | jq -r '.[] | .databaseId | @sh'
RUN_IDS=(
6955591095
6955490664
# ... add all other IDs here
)

# Loop through each run ID and delete the run
for RUN_ID in "${RUN_IDS[@]}"; do
    curl \
        -X DELETE \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$OWNER/$REPO/actions/runs/$RUN_ID"
    
    # Optional: Echo the ID of deleted run or handle errors
    if [ $? -eq 0 ]; then
        echo "Deleted run ID: $RUN_ID"
    else
        echo "Failed to delete run ID: $RUN_ID"
    fi
done
