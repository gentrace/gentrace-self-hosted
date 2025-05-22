#!/bin/bash

# MinIO bucket initialization script
# This script ensures the required bucket exists and has proper permissions

set -e

MINIO_ENDPOINT=${STORAGE_ENDPOINT:-http://minio:9000}
BUCKET_NAME=${STORAGE_BUCKET:-gentrace-public}
ACCESS_KEY=${STORAGE_ACCESS_KEY_ID:-minioadmin}
SECRET_KEY=${STORAGE_SECRET_ACCESS_KEY:-minioadmin}

echo "Waiting for MinIO to be ready..."
until curl -f "$MINIO_ENDPOINT/minio/health/live" > /dev/null 2>&1; do
    echo "MinIO not ready yet, waiting..."
    sleep 2
done

echo "MinIO is ready. Configuring mc client..."

# Configure MinIO client
mc alias set minio "$MINIO_ENDPOINT" "$ACCESS_KEY" "$SECRET_KEY"

# Check if bucket exists, create if it doesn't
if mc ls minio/"$BUCKET_NAME" > /dev/null 2>&1; then
    echo "Bucket '$BUCKET_NAME' already exists"
else
    echo "Creating bucket '$BUCKET_NAME'..."
    mc mb minio/"$BUCKET_NAME"
    echo "Bucket '$BUCKET_NAME' created successfully"
fi

# Set bucket policy to allow public read access (required for image serving)
echo "Setting public read policy for bucket '$BUCKET_NAME'..."
mc anonymous set public minio/"$BUCKET_NAME"

echo "MinIO initialization completed successfully"

