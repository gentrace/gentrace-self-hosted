#!/bin/bash

# Script to collect docker compose logs and create a tar.gz archive
# Uses only standard Debian utilities

# Set script options
set -e  # Exit on error

# Variables
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_DIR="docker_logs_${TIMESTAMP}"
ARCHIVE_FILE="docker_logs_${TIMESTAMP}.tar.gz"

# Create temporary directory for logs
echo "Creating temporary directory for logs..."
mkdir -p "${LOG_DIR}"

# Get list of all running containers
echo "Collecting logs from docker compose services..."
docker compose ps --services | while read -r service; do
    if [ -n "$service" ]; then
        echo "  - Collecting logs for service: $service"
        docker compose logs "$service" > "${LOG_DIR}/${service}.log" 2>&1 || true
    fi
done

# Also save docker compose ps output for reference
echo "Saving docker compose status..."
docker compose ps > "${LOG_DIR}/docker_compose_ps.txt" 2>&1

# Create tar.gz archive
echo "Creating tar.gz archive: ${ARCHIVE_FILE}"
tar -czf "${ARCHIVE_FILE}" "${LOG_DIR}"

# Clean up temporary directory
echo "Cleaning up temporary files..."
rm -rf "${LOG_DIR}"

echo "Done! Logs have been saved to: ${ARCHIVE_FILE}"
echo "File size: $(du -h "${ARCHIVE_FILE}" | cut -f1)"
