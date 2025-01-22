#!/bin/bash

# Change to the docker directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.." || exit 1

# Create env-files directory if it doesn't exist
mkdir -p env-files

# Function to prompt for a value with a default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt [$default]: " value
    echo "${value:-$default}"
}

echo "Gentrace Self-Hosted Environment Setup"
echo "====================================="
echo
echo "This script will help you set up your environment variables."
echo "Press Enter to accept the default values or input your own."
echo
echo "Working directory: $(pwd)"
echo

# Instructions for generating secure values
echo "Before proceeding, please generate the following secure values:"
echo
echo "1. JWT Secret Key:"
echo "   Run this command in your terminal:"
echo "   openssl rand -base64 32"
echo
echo "2. Prisma Field Encryption Key:"
echo "   Visit https://cloak.47ng.com/ to generate a key"
echo
echo "Please have these values ready before continuing."
echo
read -p "Press Enter when you're ready to continue..."
echo

# Collect all variables first
echo "Note: Passwords will be visible when typing"
ADMIN_EMAIL=$(prompt_with_default "Admin email" "admin@yourdomain.com")
ADMIN_NAME=$(prompt_with_default "Admin name" "Admin User")
ADMIN_PASSWORD=$(prompt_with_default "Admin password" "your-secure-admin-password")

POSTGRES_USER=$(prompt_with_default "PostgreSQL username" "gentrace")
POSTGRES_PASSWORD=$(prompt_with_default "PostgreSQL password" "gentrace123")
POSTGRES_DB=$(prompt_with_default "PostgreSQL database" "gentrace")

CLICKHOUSE_DATABASE=$(prompt_with_default "ClickHouse database" "gentrace")
CLICKHOUSE_USER=$(prompt_with_default "ClickHouse username" "default")
CLICKHOUSE_PASSWORD=$(prompt_with_default "ClickHouse password" "gentrace123")

STORAGE_ACCESS_KEY_ID=$(prompt_with_default "Storage access key" "your-access-key")
STORAGE_SECRET_ACCESS_KEY=$(prompt_with_default "Storage secret key" "your-secret-key")
STORAGE_ENDPOINT=$(prompt_with_default "Storage endpoint" "https://storage.googleapis.com")
STORAGE_BUCKET=$(prompt_with_default "Storage bucket" "gentrace-public")
STORAGE_REGION=$(prompt_with_default "Storage region" "us-central1")

KAFKA_BROKER=$(prompt_with_default "Kafka broker hostname" "kafka")
KAFKA_PORT=$(prompt_with_default "Kafka port" "9092")

echo "Enter your generated JWT secret (from openssl command):"
JWT_SECRET=$(prompt_with_default "JWT secret" "generate-using-openssl-command")
echo "Enter your Prisma field encryption key (from cloak website):"
PRISMA_FIELD_ENCRYPTION_KEY=$(prompt_with_default "Prisma field encryption key" "generate-from-cloak-website")

PUBLIC_HOSTNAME=$(prompt_with_default "API hostname" "api.yourdomain.com")

# Create main .env file for docker-compose
cat > .env << EOL
# Common Settings
NODE_ENV=production
ENVIRONMENT=production
NEXT_PUBLIC_SELF_HOSTED=true
NEXT_PUBLIC_SELF_HOSTED_TLS=true
NEXT_OTEL_VERBOSE=1

# Admin Configuration
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_NAME=${ADMIN_NAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

# PostgreSQL Configuration
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB}
DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}"

# ClickHouse Configuration
CLICKHOUSE_DATABASE=${CLICKHOUSE_DATABASE}
CLICKHOUSE_HOST=clickhouse
CLICKHOUSE_PORT=8123
CLICKHOUSE_PROTOCOL=http
CLICKHOUSE_USER=${CLICKHOUSE_USER}
CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}

# Kafka Configuration
KAFKA_BROKER=${KAFKA_BROKER}
KAFKA_PORT=${KAFKA_PORT}

# Object Storage Configuration
STORAGE_ACCESS_KEY_ID=${STORAGE_ACCESS_KEY_ID}
STORAGE_SECRET_ACCESS_KEY=${STORAGE_SECRET_ACCESS_KEY}
STORAGE_ENDPOINT=${STORAGE_ENDPOINT}
STORAGE_BUCKET=${STORAGE_BUCKET}
STORAGE_REGION=${STORAGE_REGION}
STORAGE_FORCE_PATH_STYLE=true

# Security
JWT_SECRET=${JWT_SECRET}
PRISMA_FIELD_ENCRYPTION_KEY=${PRISMA_FIELD_ENCRYPTION_KEY}

# Service Ports and Hostnames
PORT=3000
PUBLIC_HOSTNAME=${PUBLIC_HOSTNAME}
EOL

# Create service-specific .env files
# App Service
cat > env-files/app.env << EOL
DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}"
CLICKHOUSE_HOST=clickhouse
CLICKHOUSE_PORT=8123
CLICKHOUSE_PROTOCOL=http
CLICKHOUSE_DATABASE=${CLICKHOUSE_DATABASE}
CLICKHOUSE_USER=${CLICKHOUSE_USER}
CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}
KAFKA_BROKER=${KAFKA_BROKER}
KAFKA_PORT=${KAFKA_PORT}
STORAGE_ACCESS_KEY_ID=${STORAGE_ACCESS_KEY_ID}
STORAGE_SECRET_ACCESS_KEY=${STORAGE_SECRET_ACCESS_KEY}
STORAGE_ENDPOINT=${STORAGE_ENDPOINT}
STORAGE_BUCKET=${STORAGE_BUCKET}
STORAGE_REGION=${STORAGE_REGION}
STORAGE_FORCE_PATH_STYLE=true
PUBLIC_HOSTNAME=${PUBLIC_HOSTNAME}
PORT=3000
NEXT_PUBLIC_SELF_HOSTED=true
NEXT_PUBLIC_SELF_HOSTED_TLS=true
JWT_SECRET=${JWT_SECRET}
PRISMA_FIELD_ENCRYPTION_KEY=${PRISMA_FIELD_ENCRYPTION_KEY}
EOL

# WebSocket Server
cat > env-files/websocket.env << EOL
DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}"
CLICKHOUSE_HOST=clickhouse
CLICKHOUSE_PORT=8123
CLICKHOUSE_PROTOCOL=http
CLICKHOUSE_DATABASE=${CLICKHOUSE_DATABASE}
CLICKHOUSE_USER=${CLICKHOUSE_USER}
CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}
KAFKA_BROKER=${KAFKA_BROKER}
KAFKA_PORT=${KAFKA_PORT}
PUBLIC_HOSTNAME=${PUBLIC_HOSTNAME}
PORT=3001
NEXT_PUBLIC_SELF_HOSTED=true
NEXT_PUBLIC_SELF_HOSTED_TLS=true
JWT_SECRET=${JWT_SECRET}
PRISMA_FIELD_ENCRYPTION_KEY=${PRISMA_FIELD_ENCRYPTION_KEY}
EOL

# Task Runner
cat > env-files/taskrunner.env << EOL
DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}"
CLICKHOUSE_HOST=clickhouse
CLICKHOUSE_PORT=8123
CLICKHOUSE_PROTOCOL=http
CLICKHOUSE_DATABASE=${CLICKHOUSE_DATABASE}
CLICKHOUSE_USER=${CLICKHOUSE_USER}
CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}
KAFKA_BROKER=${KAFKA_BROKER}
KAFKA_PORT=${KAFKA_PORT}
PUBLIC_HOSTNAME=${PUBLIC_HOSTNAME}
NEXT_PUBLIC_SELF_HOSTED=true
NEXT_PUBLIC_SELF_HOSTED_TLS=true
JWT_SECRET=${JWT_SECRET}
PRISMA_FIELD_ENCRYPTION_KEY=${PRISMA_FIELD_ENCRYPTION_KEY}
STORAGE_ACCESS_KEY_ID=${STORAGE_ACCESS_KEY_ID}
STORAGE_SECRET_ACCESS_KEY=${STORAGE_SECRET_ACCESS_KEY}
STORAGE_ENDPOINT=${STORAGE_ENDPOINT}
STORAGE_BUCKET=${STORAGE_BUCKET}
STORAGE_REGION=${STORAGE_REGION}
STORAGE_FORCE_PATH_STYLE=true
EOL

# Task Scheduler
cat > env-files/taskscheduler.env << EOL
DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}"
CLICKHOUSE_HOST=clickhouse
CLICKHOUSE_PORT=8123
CLICKHOUSE_PROTOCOL=http
CLICKHOUSE_DATABASE=${CLICKHOUSE_DATABASE}
CLICKHOUSE_USER=${CLICKHOUSE_USER}
CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}
KAFKA_BROKER=${KAFKA_BROKER}
KAFKA_PORT=${KAFKA_PORT}
PUBLIC_HOSTNAME=${PUBLIC_HOSTNAME}
NEXT_PUBLIC_SELF_HOSTED=true
NEXT_PUBLIC_SELF_HOSTED_TLS=true
JWT_SECRET=${JWT_SECRET}
PRISMA_FIELD_ENCRYPTION_KEY=${PRISMA_FIELD_ENCRYPTION_KEY}
EOL

# Migration Service
cat > env-files/migrate.env << EOL
DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}"
CLICKHOUSE_HOST=clickhouse
CLICKHOUSE_PORT=8123
CLICKHOUSE_PROTOCOL=http
CLICKHOUSE_DATABASE=${CLICKHOUSE_DATABASE}
CLICKHOUSE_USER=${CLICKHOUSE_USER}
CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}
NODE_ENV=production
ENVIRONMENT=production
JWT_SECRET=${JWT_SECRET}
PRISMA_FIELD_ENCRYPTION_KEY=${PRISMA_FIELD_ENCRYPTION_KEY}
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
ADMIN_NAME=${ADMIN_NAME}
EOL

# PostgreSQL Service
cat > env-files/postgres.env << EOL
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB}
EOL

# ClickHouse Service
cat > env-files/clickhouse.env << EOL
CLICKHOUSE_USER=${CLICKHOUSE_USER}
CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}
EOL

echo
echo "Environment files created:"
echo "1. Main .env file at $(pwd)/.env"
echo "2. Service-specific .env files in $(pwd)/env-files/"
echo "Please review the generated values and adjust if needed."
echo
echo "Important:"
echo "1. Make sure you've set a secure JWT_SECRET using 'openssl rand -base64 32'"
echo "2. Ensure you've generated a proper encryption key from https://cloak.47ng.com/"
echo
echo "Note: Keep these values secure and backed up!" 