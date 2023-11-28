#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

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
        echo -e "${RED}ERROR: Filename with more than two dots are not allowed: $file${NC}"
        error_found=1
        error_message="Commit failed: Filenames with more than two dots are not allowed in 'secrets' directory."
    elif [ $dot_count -eq 2 ]; then
        # Filenames with exactly two dots
        echo -e "${GREEN}INFO: Double-dotted filename detected: $file${NC}"
    fi
done

# Exit with an error status if a problematic filename was found
if [ $error_found -eq 1 ]; then
    echo -e "${RED}$error_message${NC}"
    exit 1
fi
