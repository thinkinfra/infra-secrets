#!/bin/bash

# To execute this script:
# cd migration/staging                 # e.g., staging
# ../../scripts/convert-json-to-yaml.sh


#!/bin/bash

# Directory containing the JSON files
migration_dir="./"

echo "Starting the conversion and encryption process..."

# Iterate over all JSON files in the directory
for json_file in ${migration_dir}/*.json; do
    echo "Processing file: $json_file"

    # Extract the base filename without the extension
    base_filename=$(basename -- "$json_file")
    filename_without_ext="${base_filename%.*}"

    # Convert to YAML
    yaml_file="${migration_dir}/${filename_without_ext}.yaml"
    echo "Converting $json_file to YAML format..."
    yq eval -P "$json_file" > "$yaml_file"
    echo "Conversion completed: $yaml_file"

    # Encrypt the YAML file in-place with sops
    echo "Encrypting the YAML file: $yaml_file"
    sops -e --in-place "$yaml_file"
    if [ $? -eq 0 ]; then
        echo "Encryption successful: $yaml_file"
    else
        echo "Error occurred during encryption: $yaml_file"
        exit 1
    fi

    echo "Processing completed for $json_file"
done

# Remove all JSON files
echo "Removing all JSON files from $migration_dir..."
rm "${migration_dir}"/*.json
echo "JSON files removed."

echo "All processes completed successfully."
