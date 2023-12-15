#!/bin/bash

# To execute this script:
# cd migration/staging
# ../../scripts/migrate-secrets.sh

VAULT_ADDR="https://vault.<ENV>.earnest.com" #VAULT ADDRESS
VAULT_TOKEN="hvs.XXXXXXXXXX" #VAULT TOKEN
SECRET_PATH="secret/"

# Function to fetch and save secret
fetch_and_save_secret() {
    local path=$1
    # Authenticate with the source Vault
    vault login -no-print -address="${VAULT_ADDR}" "${VAULT_TOKEN}"
    echo "Fetching secret for: $path"
    local secret_data=$(vault kv get -address="${VAULT_ADDR}" -format=json ${path})
    echo "Raw secret data: $secret_data"

    if [[ $secret_data != "null" ]]; then
        local formatted_secret=$(echo ${secret_data} | jq '.data')
        # Remove 'secret/' prefix and replace remaining '/' with '.'
        local filename=$(echo ${path} | sed 's/^secret\///' | sed 's/\//./g')
        echo ${formatted_secret} > "${filename}.json"
    else
        echo "Secret data is null for path: $path"
    fi
}

# Authenticate with the source Vault
vault login -no-print -address="${VAULT_ADDR}" "${VAULT_TOKEN}"

# List all secrets
secrets=$(vault kv list -address="${VAULT_ADDR}" -namespace="" -format=json ${SECRET_PATH} | jq -r '.[]')

# Iterate through each secret
for secret in $secrets; do
    if [[ $secret == *"/" ]]; then
        # Authenticate with the source Vault
        vault login -no-print -address="${VAULT_ADDR}" "${VAULT_TOKEN}"
        # It's a directory, list sub-secrets
        sub_secrets=$(vault kv list -address="${VAULT_ADDR}" -namespace="" -format=json ${SECRET_PATH}${secret} | jq -r '.[]')
        for sub_secret in $sub_secrets; do
            fetch_and_save_secret "${SECRET_PATH}${secret}${sub_secret}"
        done
    else
        # It's a direct secret
        fetch_and_save_secret "${SECRET_PATH}${secret}"
    fi
done
