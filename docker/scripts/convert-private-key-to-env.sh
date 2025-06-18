#!/bin/bash

# Script to convert a private key to single line format for llm-auth.ts environment variables
# Purpose: Formats RSA private keys for use with app/src/server/apiStandards/llm-auth.ts
# Usage: ./convert-private-key-to-env.sh <private_key_file>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <private_key_file>"
    echo "Example: $0 private_key.pem"
    echo ""
    echo "This script formats RSA private keys for use with llm-auth.ts"
    echo "The output can be used for the LLM_AUTH_PK_VALUE environment variable"
    exit 1
fi

KEY_FILE="$1"

if [ ! -f "$KEY_FILE" ]; then
    echo "Error: File '$KEY_FILE' not found"
    exit 1
fi

# Read the file and convert newlines to literal \n
# This preserves the PEM format structure when stored as a single line
ONE_LINE_KEY=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' "$KEY_FILE" | sed 's/\\n$//')

# Output the result
echo "# Add this to your .env file or export it for llm-auth.ts:"
echo "LLM_AUTH_PK_VALUE=\"$ONE_LINE_KEY\""

# Optionally, also show just the raw value for copying
echo ""
echo "# Or just the value:"
echo "$ONE_LINE_KEY" 
