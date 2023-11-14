#!/bin/bash
# write_secret.sh

SECRET_VALUE="$1"
SECRET_TEMP_FILE=$(mktemp)
echo "$SECRET_VALUE" > "$SECRET_TEMP_FILE"
echo "$SECRET_TEMP_FILE"