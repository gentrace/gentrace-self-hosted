#!/bin/bash

# MinIO bucket initialization script
# This script ensures the required bucket exists and has proper permissions

set -e

MINIO_ENDPOINT=${STORAGE_ENDPOINT:-http://minio:9000}
BUCKET_NAME=${STORAGE_BUCKET:-gentrace-public}
ACCESS_KEY=${STORAGE_ACCESS_KEY_ID:-minioadmin}
SECRET_KEY=${STORAGE_SECRET_ACCESS_KEY:-minioadmin}

echo "Configuring mc client for MinIO checks..."
mc alias set minio "$MINIO_ENDPOINT" "$ACCESS_KEY" "$SECRET_KEY" --api "s3v4"

echo "Waiting for MinIO to be ready..."
until mc admin info minio --json > /dev/null 2>&1; do
    echo "MinIO not ready yet, waiting..."
    sleep 2
done

echo "MinIO is ready."
# No need to re-configure mc client here as it was done above for the check

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

