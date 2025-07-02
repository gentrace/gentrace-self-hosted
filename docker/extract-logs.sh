#!/bin/bash

# Script to extract docker compose logs from tar.gz archive
# Uses only standard Debian utilities

# Set script options
set -e  # Exit on error

# Check if argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <log_archive.tar.gz>"
    echo "Example: $0 docker_logs_20240102_143022.tar.gz"
    exit 1
fi

ARCHIVE_FILE="$1"

# Check if file exists
if [ ! -f "$ARCHIVE_FILE" ]; then
    echo "Error: File '$ARCHIVE_FILE' not found!"
    exit 1
fi

# Check if file has correct extension
if [[ ! "$ARCHIVE_FILE" =~ \.tar\.gz$ ]]; then
    echo "Error: File must be a .tar.gz archive!"
    exit 1
fi

# Extract archive
echo "Extracting logs from: $ARCHIVE_FILE"
tar -xzf "$ARCHIVE_FILE"

# Get the directory name (tar will create it)
EXTRACTED_DIR=$(tar -tzf "$ARCHIVE_FILE" | head -1 | cut -d'/' -f1)

echo "Logs extracted to directory: $EXTRACTED_DIR"
echo ""
echo "Contents:"
ls -la "$EXTRACTED_DIR"
echo ""
echo "To view a specific log:"
echo "  cat $EXTRACTED_DIR/<service_name>.log"
echo ""
echo "To view all logs:"
echo "  less $EXTRACTED_DIR/*.log"