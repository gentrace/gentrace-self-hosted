#!/bin/bash

# Change to the docker directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.." || exit 1

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

# Create .env file
echo "Note: Passwords will be visible when typing"
ADMIN_PASSWORD=$(prompt_with_default "Admin password" "your-secure-admin-password")
POSTGRES_PASSWORD=$(prompt_with_default "PostgreSQL password" "gentrace123")
CLICKHOUSE_PASSWORD=$(prompt_with_default "ClickHouse password" "gentrace123")
STORAGE_SECRET_ACCESS_KEY=$(prompt_with_default "Storage secret key" "your-secret-key")

echo "Enter your generated JWT secret (from openssl command):"
JWT_SECRET=$(prompt_with_default "JWT secret" "generate-using-openssl-command")
echo "Enter your Prisma field encryption key (from cloak website):"
PRISMA_FIELD_ENCRYPTION_KEY=$(prompt_with_default "Prisma field encryption key" "generate-from-cloak-website")

cat > .env << EOL
# Common Settings
NODE_ENV=$(prompt_with_default "Node environment" "production")
ENVIRONMENT=$(prompt_with_default "Environment" "production")
NEXT_PUBLIC_SELF_HOSTED=true
NEXT_PUBLIC_SELF_HOSTED_TLS=$(prompt_with_default "Enable TLS" "true")
NEXT_OTEL_VERBOSE=1

# Admin Configuration
ADMIN_EMAIL=$(prompt_with_default "Admin email" "admin@yourdomain.com")
ADMIN_NAME=$(prompt_with_default "Admin name" "Admin User")
ADMIN_PASSWORD=\${ADMIN_PASSWORD}

# PostgreSQL Configuration
POSTGRES_USER=$(prompt_with_default "PostgreSQL username" "gentrace")
POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
POSTGRES_DB=$(prompt_with_default "PostgreSQL database" "gentrace")
DATABASE_URL="postgresql://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@postgres:5432/\${POSTGRES_DB}"

# ClickHouse Configuration
CLICKHOUSE_DATABASE=$(prompt_with_default "ClickHouse database" "gentrace")
CLICKHOUSE_HOST=clickhouse
CLICKHOUSE_PORT=8123
CLICKHOUSE_PROTOCOL=http
CLICKHOUSE_USER=$(prompt_with_default "ClickHouse username" "default")
CLICKHOUSE_PASSWORD=\${CLICKHOUSE_PASSWORD}

# Kafka Configuration
KAFKA_BROKER=kafka
KAFKA_PORT=9092

# Object Storage Configuration
STORAGE_ACCESS_KEY_ID=$(prompt_with_default "Storage access key" "your-access-key")
STORAGE_SECRET_ACCESS_KEY=\${STORAGE_SECRET_ACCESS_KEY}
STORAGE_ENDPOINT=$(prompt_with_default "Storage endpoint" "https://storage.googleapis.com")
STORAGE_BUCKET=$(prompt_with_default "Storage bucket" "gentrace-public")
STORAGE_REGION=$(prompt_with_default "Storage region" "us-central1")
STORAGE_FORCE_PATH_STYLE=true

# Security
JWT_SECRET=\${JWT_SECRET}
PRISMA_FIELD_ENCRYPTION_KEY=\${PRISMA_FIELD_ENCRYPTION_KEY}

# Service Ports and Hostnames
PORT=3000
PUBLIC_HOSTNAME=$(prompt_with_default "API hostname" "api.yourdomain.com")
WEBSOCKET_PORT=3001
WEBSOCKET_HOSTNAME=$(prompt_with_default "WebSocket hostname" "ws.yourdomain.com")
TASKRUNNER_HOSTNAME=$(prompt_with_default "Task Runner hostname" "taskrunner.yourdomain.com")
SCHEDULER_HOSTNAME=$(prompt_with_default "Scheduler hostname" "scheduler.yourdomain.com")
EOL

echo
echo "Environment file created at $(pwd)/.env"
echo "Please review the generated values and adjust if needed."
echo
echo "Important:"
echo "1. Make sure you've set a secure JWT_SECRET using 'openssl rand -base64 32'"
echo "2. Ensure you've generated a proper encryption key from https://cloak.47ng.com/"
echo
echo "Note: Keep these values secure and backed up!" 