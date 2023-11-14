#!/bin/bash
# wrapper.sh

# Access the secret value from the environment variable
secret_value="$SECRET_VALUE"

# Call the original script with the secret value
secret_temp_file=$(./scripts/write_secret.sh "$secret_value")

# Output the path of the temporary file
echo "$secret_temp_file"