#!/bin/bash

# Initialize a flag to indicate an error
error_found=0

# Loop through files in the 'secrets' directory
for file in $(find secrets -type f -name "*.*.*"); do
    if [[ $(basename "$file") =~ (\.{3})\.yaml$ ]]; then
        # Triple-dotted filenames found
        echo "Error: Triple-dotted filename not allowed: $file"
        error_found=1
    elif [[ $(basename "$file") =~ (\.{2})\.yaml$ ]]; then
        # Double-dotted filenames found
        echo "INFO: Double-dotted filename is used for sub-path: $file"
    fi
done

# Exit with an error status if a triple-dotted filename was found
if [ $error_found -eq 1 ]; then
    exit 1
fi
