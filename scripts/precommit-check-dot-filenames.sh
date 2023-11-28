#!/bin/bash

# Initialize a flag to indicate an error
error_found=0
error_message=""

# Loop through YAML files in the 'secrets' directory
for file in $(find secrets -type f -name "*.yaml"); do
    filename=$(basename "$file")

    # Count the number of dots in the filename (excluding the extension)
    dot_count=$(grep -o "\." <<< "$filename" | grep -c .)

    if [ $dot_count -gt 2 ]; then
        # Filenames with more than two dots (excluding the .yaml extension)
        echo "ERROR: Filename with more than two dots not allowed: $file"
        error_found=1
        error_message="Commit failed: Filenames with more than two dots are not allowed in 'secrets' directory."
    elif [ $dot_count -eq 2 ]; then
        # Filenames with exactly two dots
        echo "INFO: Double-dotted filename detected: $file"
    fi
done

# Exit with an error status if a problematic filename was found
if [ $error_found -eq 1 ]; then
    echo "$error_message"
    exit 1
fi
