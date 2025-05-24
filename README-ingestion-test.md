# Gentrace Self-Hosted Ingestion Pipeline Test

This directory contains a comprehensive test suite for validating the full Gentrace self-hosted container setup, specifically testing the data ingestion pipeline from OpenTelemetry endpoint to database storage.

## Overview

The test validates the complete data flow:
1. **OTEL Ingestion**: Sends OpenTelemetry traces to `/api/otel/v1/traces`
2. **Postgres Storage**: Validates data appears in the `GTSpan` table
3. **ClickHouse Replication**: Validates data is replicated to the `span` table

## Files

- `test-ingestion-pipeline.py` - Python test script using OpenTelemetry Python SDK
- `test-ingestion-node.js` - Node.js test script using OpenTelemetry Node SDK
- `run-ingestion-test.sh` - Shell script to run tests with proper setup
- `package.json` - Node.js dependencies
- `requirements-test.txt` - Python dependencies
- `validate-postgres.sql` - Manual Postgres validation queries
- `validate-clickhouse.sql` - Manual ClickHouse validation queries

## Quick Start

1. **Start the self-hosted environment**:
   ```bash
   cd docker
   docker-compose up -d
   ```

2. **Run the automated test**:
   ```bash
   # Run Python test (default)
   ./run-ingestion-test.sh
   
   # Run Node.js test
   ./run-ingestion-test.sh node
   
   # Run both Python and Node.js tests
   ./run-ingestion-test.sh both
   ```

## Manual Setup

If you prefer to run the tests manually:

### Python Test

1. **Install dependencies**:
   ```bash
   pip3 install -r requirements-test.txt
   ```

2. **Run the test**:
   ```bash
   python3 test-ingestion-pipeline.py
   ```

### Node.js Test

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Run the test**:
   ```bash
   node test-ingestion-node.js
   ```

### Environment Variables

Set these environment variables (optional, defaults provided):
```bash
export GENTRACE_BASE_URL="http://localhost:3000"
export POSTGRES_HOST="localhost"
export POSTGRES_PORT="5432"
export POSTGRES_DB="gentrace"
export POSTGRES_USER="postgres"
export POSTGRES_PASSWORD="password"
export CLICKHOUSE_HOST="localhost"
export CLICKHOUSE_PORT="8123"
export CLICKHOUSE_DB="default"
export CLICKHOUSE_USER="default"
export CLICKHOUSE_PASSWORD=""
export GENTRACE_API_KEY="your-api-key"
export ORGANIZATION_ID="your-org-id"
export PIPELINE_ID="your-pipeline-id"
```

## Test Details

### What the Test Does

1. **Health Check**: Verifies the Gentrace API is accessible
2. **OTEL Trace Generation**: Creates and sends three types of test traces:
   - Simple interaction trace
   - LLM call trace with messages and choices
   - Exception/error trace
3. **Postgres Validation**: Queries the `GTSpan` table to verify:
   - Traces were ingested
   - Required fields are populated
   - OTEL source data is preserved
   - Attributes are correctly mapped
4. **ClickHouse Validation**: Queries the `span` table to verify:
   - Data was replicated from Postgres
   - JSON fields are valid
   - Timestamps are correct

### Expected Output

```
🚀 Starting Gentrace ingestion pipeline test
   Base URL: http://localhost:3000
   Postgres: localhost:5432
   ClickHouse: localhost:8123

🏥 Testing API endpoint health...
✅ API endpoint is accessible

📤 Sending test OpenTelemetry traces...
✅ Sent 3 test traces

🔍 Validating Postgres ingestion...
  ✅ Found span: test-interaction (type: interaction, trace: 1a2b3c4d...)
  ✅ Found span: test-llm-call (type: llm, trace: 5e6f7g8h...)
  �� Found span: test-exception (type: function, trace: 9i0j1k2l...)
✅ Postgres validation successful: 3/3 traces found

🔍 Validating ClickHouse replication...
  ✅ Found ClickHouse span: test-interaction (id: 1a2b3c4d...)
  ✅ Found ClickHouse span: test-llm-call (id: 5e6f7g8h...)
  ✅ Found ClickHouse span: test-exception (id: 9i0j1k2l...)
✅ ClickHouse validation successful: 3 spans found

📊 Test Results Summary:
   API Health: ✅
   Trace Sending: ✅
   Postgres Ingestion: ✅
   ClickHouse Replication: ✅

🎉 All tests passed! Ingestion pipeline is working correctly.
```

## Manual Validation

You can also run manual validation queries:

### Postgres
```bash
psql -h localhost -p 5432 -U postgres -d gentrace -f validate-postgres.sql
```

### ClickHouse
```bash
clickhouse-client --host localhost --port 9000 --queries-file validate-clickhouse.sql
```

## Troubleshooting

### Common Issues

1. **Connection Refused**:
   - Ensure docker-compose services are running: `docker-compose ps`
   - Check port mappings in docker-compose.yml
   - Verify firewall settings

2. **Authentication Errors**:
   - Check API key format (should start with `gt-`)
   - Verify organization ID exists in the database
   - Ensure API key has proper permissions

3. **No Data in Postgres**:
   - Check application logs: `docker-compose logs app`
   - Verify OTEL endpoint is receiving data
   - Check for buffered spans that haven't been processed

4. **No Data in ClickHouse**:
   - Data replication may be asynchronous - wait longer
   - Check task runner logs: `docker-compose logs taskrunner`
   - Verify ClickHouse connection from the app

### Debug Commands

```bash
# Check service status
docker-compose ps

# View application logs
docker-compose logs app

# View task runner logs (handles ClickHouse replication)
docker-compose logs taskrunner

# Connect to Postgres
docker-compose exec postgres psql -U postgres -d gentrace

# Connect to ClickHouse
docker-compose exec clickhouse clickhouse-client

# Check API endpoint directly
curl -v http://localhost:3000/api/health
```

## Architecture Notes

### Data Flow
```
OpenTelemetry SDK → OTLP HTTP → /api/otel/v1/traces → bufferedInsertGTSpans → Postgres GTSpan → Task Runner → ClickHouse span
```

### Key Components
- **OTEL Endpoint**: `/api/otel/v1/traces` accepts OTLP traces
- **Postgres GTSpan**: Primary storage with full trace data
- **ClickHouse span**: Analytics storage with compressed data
- **Task Runner**: Handles async replication to ClickHouse

### Database Schemas

**Postgres GTSpan** (key fields):
- `id`, `traceId`, `threadId` - Identifiers
- `sourceOtelSpan`, `sourceOtelScope`, `sourceOtelResource` - Raw OTEL data
- `attributesMap` - Span attributes as JSON
- `functionArgs`, `functionOutput` - Function call data
- `llmMessages`, `llmChoices` - LLM-specific data

**ClickHouse span** (key fields):
- `id`, `name` - Basic identifiers
- `inputs`, `outputs` - Compressed JSON data
- `metadata` - Additional span metadata
- `startTime`, `endTime` - Timing information

## Contributing

To extend the test:

1. Add new trace types in `send_test_traces()`
2. Add validation logic in `validate_postgres_ingestion()` or `validate_clickhouse_replication()`
3. Update the SQL validation files for manual testing
4. Test with different OTEL configurations and data patterns
