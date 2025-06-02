#!/bin/bash

# Gentrace Self-Hosted Ingestion Pipeline Test Runner
# This script sets up the environment and runs the comprehensive ingestion tests

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Gentrace Self-Hosted Ingestion Pipeline Test"
echo "================================================"

# Parse command line arguments
TEST_TYPE="python"
if [[ "$1" == "node" || "$1" == "nodejs" || "$1" == "typescript" || "$1" == "ts" ]]; then
    TEST_TYPE="typescript"
elif [[ "$1" == "both" || "$1" == "all" ]]; then
    TEST_TYPE="both"
elif [[ "$1" == "python" || "$1" == "py" ]]; then
    TEST_TYPE="python"
elif [[ -n "$1" ]]; then
    echo "❌ Unknown test type: $1"
    echo "Usage: $0 [python|typescript|both]"
    exit 1
fi

echo "🔧 Test type: $TEST_TYPE"

# Check if docker compose is running
cd "$DOCKER_DIR"
if ! docker compose ps | grep -q "Up"; then
    echo "❌ Docker compose services are not running!"
    echo "Please start the services first:"
    echo "  cd docker && docker compose up -d"
    exit 1
fi

echo "✅ Docker compose services are running"

# Set default environment variables if not already set
export GENTRACE_BASE_URL="${GENTRACE_BASE_URL:-http://localhost:3000}"
export POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
export POSTGRES_PORT="${POSTGRES_PORT:-5432}"
export POSTGRES_DB="${POSTGRES_DB:-gentrace}"
export POSTGRES_USER="${POSTGRES_USER:-gentrace}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-gentrace123}"
export CLICKHOUSE_HOST="${CLICKHOUSE_HOST:-localhost}"
export CLICKHOUSE_PORT="${CLICKHOUSE_PORT:-8123}"
export CLICKHOUSE_DB="${CLICKHOUSE_DB:-default}"
export CLICKHOUSE_USER="${CLICKHOUSE_USER:-default}"
export CLICKHOUSE_PASSWORD="${CLICKHOUSE_PASSWORD:-gentrace123}"

# Use the provided API key
export GENTRACE_API_KEY="${GENTRACE_API_KEY:-gen_api_x6cPoAJR5Fb63xaTcUcYU1A64PDPUGlppkMDEL2J}"
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

# Run the tests
OVERALL_SUCCESS=true

if [[ "$TEST_TYPE" == "python" || "$TEST_TYPE" == "both" ]]; then
    echo "🧪 Running Python ingestion pipeline test..."
    cd "$SCRIPT_DIR/python"
    
    # Check if uv is installed
    if ! command -v uv &> /dev/null; then
        echo "❌ uv is not installed. Please install it: https://github.com/astral-sh/uv"
        exit 1
    fi
    
    # Install dependencies if needed
    if [[ ! -d ".venv" ]]; then
        echo "📦 Installing Python dependencies..."
        uv sync --pre
    fi
    
    if uv run test-ingestion; then
        echo "✅ Python test passed"
    else
        echo "❌ Python test failed"
        OVERALL_SUCCESS=false
    fi
    echo ""
fi

if [[ "$TEST_TYPE" == "typescript" || "$TEST_TYPE" == "both" ]]; then
    echo "🧪 Running TypeScript/Node.js ingestion pipeline test..."
    cd "$SCRIPT_DIR/typescript"
    
    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        echo "📦 Installing Node.js dependencies..."
        npm install
    fi
    
    if npm test; then
        echo "✅ TypeScript/Node.js test passed"
    else
        echo "❌ TypeScript/Node.js test failed"
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