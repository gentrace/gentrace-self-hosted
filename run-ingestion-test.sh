#!/bin/bash

# Gentrace Self-Hosted Ingestion Pipeline Test Runner
# This script sets up the environment and runs the comprehensive ingestion test

set -e

echo "🚀 Gentrace Self-Hosted Ingestion Pipeline Test"
echo "================================================"

# Parse command line arguments
TEST_TYPE="python"
if [[ "$1" == "node" || "$1" == "nodejs" ]]; then
    TEST_TYPE="node"
elif [[ "$1" == "both" || "$1" == "all" ]]; then
    TEST_TYPE="both"
elif [[ "$1" == "python" || "$1" == "py" ]]; then
    TEST_TYPE="python"
elif [[ -n "$1" ]]; then
    echo "❌ Unknown test type: $1"
    echo "Usage: $0 [python|node|both]"
    exit 1
fi

echo "🔧 Test type: $TEST_TYPE"

# Check if docker-compose is running
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Docker compose services are not running!"
    echo "Please start the services first:"
    echo "  cd docker && docker-compose up -d"
    exit 1
fi

echo "✅ Docker compose services are running"

# Install dependencies based on test type
if [[ "$TEST_TYPE" == "python" || "$TEST_TYPE" == "both" ]]; then
    if ! python3 -c "import requests, psycopg2, clickhouse_driver, opentelemetry" 2>/dev/null; then
        echo "📦 Installing Python dependencies..."
        pip3 install -r requirements-test.txt
    fi
fi

if [[ "$TEST_TYPE" == "node" || "$TEST_TYPE" == "both" ]]; then
    if [[ ! -d "node_modules" ]]; then
        echo "📦 Installing Node.js dependencies..."
        npm install
    fi
fi

# Set default environment variables if not already set
export GENTRACE_BASE_URL="${GENTRACE_BASE_URL:-http://localhost:3000}"
export POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
export POSTGRES_PORT="${POSTGRES_PORT:-5432}"
export POSTGRES_DB="${POSTGRES_DB:-gentrace}"
export POSTGRES_USER="${POSTGRES_USER:-postgres}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-password}"
export CLICKHOUSE_HOST="${CLICKHOUSE_HOST:-localhost}"
export CLICKHOUSE_PORT="${CLICKHOUSE_PORT:-8123}"
export CLICKHOUSE_DB="${CLICKHOUSE_DB:-default}"
export CLICKHOUSE_USER="${CLICKHOUSE_USER:-default}"
export CLICKHOUSE_PASSWORD="${CLICKHOUSE_PASSWORD:-}"

# Generate test API key and organization ID if not set
export GENTRACE_API_KEY="${GENTRACE_API_KEY:-gt-test-$(date +%s)}"
export ORGANIZATION_ID="${ORGANIZATION_ID:-test-org-$(date +%s)}"
export PIPELINE_ID="${PIPELINE_ID:-test-pipeline-$(date +%s)}"

echo "🔧 Configuration:"
echo "   Base URL: $GENTRACE_BASE_URL"
echo "   Postgres: $POSTGRES_HOST:$POSTGRES_PORT"
echo "   ClickHouse: $CLICKHOUSE_HOST:$CLICKHOUSE_PORT"
echo "   API Key: ${GENTRACE_API_KEY:0:10}..."
echo ""

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check if Postgres is accessible
if ! nc -z $POSTGRES_HOST $POSTGRES_PORT 2>/dev/null; then
    echo "❌ Cannot connect to Postgres at $POSTGRES_HOST:$POSTGRES_PORT"
    echo "Make sure the postgres service is running and accessible"
    exit 1
fi

# Check if ClickHouse is accessible
if ! nc -z $CLICKHOUSE_HOST $CLICKHOUSE_PORT 2>/dev/null; then
    echo "❌ Cannot connect to ClickHouse at $CLICKHOUSE_HOST:$CLICKHOUSE_PORT"
    echo "Make sure the clickhouse service is running and accessible"
    exit 1
fi

# Check if Gentrace app is accessible
if ! curl -s -f "$GENTRACE_BASE_URL/api/health" >/dev/null 2>&1; then
    echo "❌ Cannot connect to Gentrace app at $GENTRACE_BASE_URL"
    echo "Make sure the app service is running and accessible"
    exit 1
fi

echo "✅ All services are accessible"
echo ""

# Run the tests
OVERALL_SUCCESS=true

if [[ "$TEST_TYPE" == "python" || "$TEST_TYPE" == "both" ]]; then
    echo "🧪 Running Python ingestion pipeline test..."
    if python3 test-ingestion-pipeline.py; then
        echo "✅ Python test passed"
    else
        echo "❌ Python test failed"
        OVERALL_SUCCESS=false
    fi
    echo ""
fi

if [[ "$TEST_TYPE" == "node" || "$TEST_TYPE" == "both" ]]; then
    echo "🧪 Running Node.js ingestion pipeline test..."
    if node test-ingestion-node.js; then
        echo "✅ Node.js test passed"
    else
        echo "❌ Node.js test failed"
        OVERALL_SUCCESS=false
    fi
    echo ""
fi

echo "🏁 Test completed!"

if [[ "$OVERALL_SUCCESS" == "true" ]]; then
    echo "🎉 All tests passed successfully!"
    exit 0
else
    echo "💥 Some tests failed!"
    exit 1
fi
