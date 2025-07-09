#!/bin/bash
# Script to ensure ClickHouse tables are properly set up for testing

echo "Checking ClickHouse tables..."

# List existing tables
echo "=== Current tables in ClickHouse ==="
docker compose exec -T clickhouse clickhouse client --database=default --query "SHOW TABLES"

# Check if GTSpan table exists
if docker compose exec -T clickhouse clickhouse client --database=default --query "EXISTS TABLE GTSpan" 2>/dev/null | grep -q "1"; then
    echo "GTSpan table already exists"
else
    echo "GTSpan table does not exist, checking for span table..."
    
    # Check if span table exists
    if docker compose exec -T clickhouse clickhouse client --database=default --query "EXISTS TABLE span" 2>/dev/null | grep -q "1"; then
        echo "Found span table, creating GTSpan as a view..."
        # Create GTSpan as a view of span table
        docker compose exec -T clickhouse clickhouse client --database=default --query "
        CREATE VIEW IF NOT EXISTS GTSpan AS 
        SELECT * FROM span
        " || echo "Failed to create GTSpan view"
    else
        echo "Neither GTSpan nor span table exists, creating GTSpan table..."
        # Create GTSpan table with the expected schema
        docker compose exec -T clickhouse clickhouse client --database=default --query "
        CREATE TABLE IF NOT EXISTS GTSpan (
            id String,
            name String,
            functionArgs String,
            functionOutput String,
            startTime DateTime64(3),
            endTime DateTime64(3),
            attributesMap String,
            traceId String,
            pipelineId Nullable(String),
            createdAt DateTime64(3) DEFAULT now()
        )
        ENGINE = MergeTree()
        ORDER BY (createdAt, id)
        PARTITION BY toYYYYMM(createdAt)
        " || echo "Failed to create GTSpan table"
    fi
fi

echo "=== Final table list ==="
docker compose exec -T clickhouse clickhouse client --database=default --query "SHOW TABLES"