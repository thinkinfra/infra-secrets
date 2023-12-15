#!/bin/bash

# To execute this script:
# cd migration/staging
# ../../scripts/migrate-secrets-with-lists.sh


VAULT_ADDR="https://vault.<ENV>.earnest.com" #VAULT ADDRESS
VAULT_TOKEN="hvs.XXXXXXXXXX" #VAULT TOKEN
SECRET_PATH="secret/" # Constant prefix for Vault paths
SECRETS_FILE="lists/secrets_lists.txt" # File containing list of secrets

# Function to fetch and save secret
fetch_and_save_secret() {
    local secret_path=$1
    local vault_path=$2

    # Combine the secret path and the vault path
    local full_path="${secret_path}${vault_path}"

    echo "Fetching secret for: $full_path"
    local secret_data=$(vault kv get -address="${VAULT_ADDR}" -format=json "$full_path")
    # echo "Raw secret data: $secret_data"

    if [[ $secret_data != "null" ]]; then
        local formatted_secret=$(echo ${secret_data} | jq '.data')
        # Replace '/' with '.' in vault_path and append '.json' for filename
        local filename=$(echo "${vault_path}" | sed 's/\//./g').json

        echo ${formatted_secret} > "${filename}"
    else
        echo "Secret data is null for path: $full_path"
    fi
}

# Authenticate with the source Vault
vault login -no-print -address="${VAULT_ADDR}" "${VAULT_TOKEN}"

# Read each line from the secrets file and process it
while IFS= read -r line || [[ -n "$line" ]]; do
    echo "----------------------"
    echo "Read line: '$line'" # Debugging line

    # Replace '/' with '.' in the vault path and append '.json' for filename
    vault_path=$(echo "${line}" | sed 's/\./\//g')
    echo "Processed vault_path: '$vault_path'" # Debugging line

    fetch_and_save_secret "${SECRET_PATH}" "${vault_path}"

    echo "Processed secret for: $vault_path"
done < "$SECRETS_FILE"

echo "Finished processing all secrets."
