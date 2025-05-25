#!/bin/bash

# Minimal seed script runner for self-hosted docker-compose testing
# This script runs the minimal seed to populate test data

set -e

echo "🌱 Running minimal seed for self-hosted testing..."

# Check if we're in the docker directory
if [ ! -f "seed-minimal.ts" ]; then
    echo "❌ Error: seed-minimal.ts not found. Make sure you're in the docker directory."
    exit 1
fi

# Check if required environment variables are set
if [ -z "$DATABASE_URL" ]; then
    echo "❌ Error: DATABASE_URL environment variable is required"
    exit 1
fi

# Install dependencies if needed (for standalone testing)
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm init -y 2>/dev/null || true
    npm install @prisma/client prisma-field-encryption typescript tsx 2>/dev/null || true
fi

# Run the seed script
echo "🚀 Executing minimal seed..."
npx tsx seed-minimal.ts

echo "✅ Minimal seed completed successfully!"

