# Gentrace Self-Hosted Ingestion Pipeline Tests

This directory contains comprehensive test suites for validating the full Gentrace self-hosted container setup, specifically testing the data ingestion pipeline using the Gentrace SDK.

## Directory Structure

```
ingestion-tests/
├── python/          # Python test implementation using uv and Gentrace SDK
├── typescript/      # TypeScript test implementation using Gentrace SDK
└── README.md       # This file
```

## Overview

The tests validate the complete data flow using the Gentrace SDK:

1. **SDK Integration**: Uses Gentrace SDK's `init()` and `interaction()` functions
2. **OTEL Ingestion**: Sends OpenTelemetry traces via SDK to `/api/otel/v1/traces`
3. **Postgres Storage**: Validates data appears in the `GTSpan` table
4. **ClickHouse Replication**: Validates data is replicated to the `GTSpan` table

## Quick Start

1. **Start the self-hosted environment**:

   ```bash
   cd docker
   docker compose up -d
   ```

2. **Run the automated tests**:

   ### Python Tests

   ```bash
   cd ingestion-tests/python
   uv sync --pre  # Install dependencies including alpha version
   uv run python test_ingestion_pipeline.py
   ```

   **Note**: The Python test requires `gentrace-py` alpha version which has known compatibility issues with Python 3.13+. Use Python 3.12 or earlier.

   ### TypeScript/Node.js Tests

   ```bash
   cd ingestion-tests/typescript
   npm install  # Install dependencies
   npm test     # Run with tsx
   ```

## Test Implementations

### Python (`python/`)

- Uses `uv` for dependency management
- Implements tests using official Gentrace Python SDK (`gentrace-py` v1.0.0 alpha)
- Uses SDK's `@interaction` decorator for function tracing
- **Note**: Currently has compatibility issues with Python 3.13+. Use Python 3.12 or earlier.
- Uses HTTP interface for ClickHouse queries to handle authentication properly
- See `python/README.md` for detailed setup instructions

### TypeScript/Node.js (`typescript/`)

- Uses `npm` for dependency management
- Written in TypeScript for type safety
- Executed with `tsx` for direct TypeScript execution
- Implements tests using Gentrace JavaScript SDK (`@gentrace/core`)
- Uses SDK's `interaction()` function for function tracing
- Includes proper TypeScript configuration with Node.js types
- Uses Pino for structured logging
- See `typescript/README.md` for detailed setup instructions

## Environment Variables

Both test implementations support the following environment variables (with defaults):

```bash
export GENTRACE_BASE_URL="http://localhost:3000/api"
export POSTGRES_HOST="localhost"
export POSTGRES_PORT="5432"
export POSTGRES_DB="gentrace"
export POSTGRES_USER="gentrace"
export POSTGRES_PASSWORD="gentrace123"
export CLICKHOUSE_HOST="localhost"
export CLICKHOUSE_PORT="8123"
export CLICKHOUSE_DB="default"
export CLICKHOUSE_USER="default"
export CLICKHOUSE_PASSWORD=""  # Empty password for local ClickHouse
export GENTRACE_API_KEY="gen_api_x6cPoAJR5Fb63xaTcUcYU1A64PDPUGlppkMDEL2J"
export ORGANIZATION_ID="your-org-id"
export PIPELINE_ID="c10408c7-abde-5c19-b339-e8b1087c9b64"  # Default test pipeline
```

## Test Details

### What the Tests Do

1. **SDK Initialization**: Initialize Gentrace SDK with API key and base URL
2. **Function Wrapping**: Use SDK's `interaction()` to wrap test functions:
   - Simple interaction trace
   - LLM call trace with messages and choices
   - Exception/error trace
3. **Automatic Tracing**: The SDK automatically:
   - Creates OpenTelemetry spans
   - Records function arguments and outputs
   - Manages OpenTelemetry baggage
   - Associates spans with the specified pipeline
4. **Postgres Validation**: Queries the `GTSpan` table to verify:
   - Traces were ingested
   - Required fields are populated
   - Pipeline association is correct
   - SDK-specific attributes are present (nested structure: `attributesMap.test.framework`)
5. **ClickHouse Validation**: Queries the `GTSpan` table to verify:
   - Data was replicated from Postgres
   - JSON fields are valid (functionArgs, functionOutput, attributesMap)
   - Timestamps are correct
   - **Note**: ClickHouse replication is eventually consistent, tests wait up to 2 minutes with a 2-second initial settling period

### SDK Features Used

- **`init()`**: Initialize the SDK with configuration
- **`interaction()`**: Wrap functions to create traced interactions
- **`GentraceSampler`**: Custom sampler for OpenTelemetry (Python)
- **`GentraceSpanProcessor`**: Span processor for baggage management (Python)
- **Pipeline Association**: Automatically associates traces with specified pipeline ID
- **Error Handling**: Automatic exception recording and span status setting
- **Baggage Management**: SDK handles OpenTelemetry baggage for proper sampling

### Expected Output

```
🚀 Starting Gentrace ingestion pipeline test (using Gentrace SDK)
   Base URL: http://localhost:3000/api
   Postgres: localhost:5432
   ClickHouse: localhost:8123
   Pipeline ID: c10408c7-abde-5c19-b339-e8b1087c9b64

📤 Sending test OpenTelemetry traces using Gentrace SDK...
  ✅ Sent simple interaction trace: 1a2b3c4d...
  ✅ Sent LLM call trace: 5e6f7g8h...
  ✅ Sent error trace: 9i0j1k2l...
✅ Sent 3 test traces using Gentrace SDK

🔍 Validating Postgres ingestion...
  ✅ Found span: test-interaction (type: INTERACTION, trace: 1a2b3c4d...)
  ✅ Found span: test-llm-call (type: INTERACTION, trace: 5e6f7g8h...)
  ✅ Found span: test-exception (type: INTERACTION, trace: 9i0j1k2l...)
✅ Postgres validation successful: 3 spans found

🔍 Validating ClickHouse replication...
   Note: ClickHouse replication is eventually consistent, allowing extra time...
   ⏳ Waiting 2 seconds for ClickHouse replication to settle...
  ✅ Found ClickHouse span: test-interaction (id: 1a2b3c4d...)
    ✅ Valid functionArgs JSON
    ✅ Valid functionOutput JSON
  ✅ Found ClickHouse span: test-llm-call (id: 5e6f7g8h...)
    ✅ Valid functionArgs JSON
    ✅ Valid functionOutput JSON
  ✅ Found ClickHouse span: test-exception (id: 9i0j1k2l...)
    ✅ Valid functionArgs JSON
    ✅ Valid functionOutput JSON
✅ ClickHouse validation successful: 3 spans found

📊 Test Results Summary:
   Trace Sending: ✅
   Postgres Ingestion: ✅
   ClickHouse Replication: ✅

🎉 All tests passed! Ingestion pipeline is working correctly.
```

## Manual Validation

You can manually query the databases to verify the data:

### Postgres

```bash
docker compose exec postgres psql -U gentrace -d gentrace -c "SELECT id, name, type, \"pipelineId\" FROM \"GTSpan\" WHERE \"pipelineId\" = 'c10408c7-abde-5c19-b339-e8b1087c9b64' ORDER BY \"createdAt\" DESC LIMIT 10;"
```

### ClickHouse

```bash
docker compose exec clickhouse clickhouse-client --query="SELECT id, name, functionArgs, functionOutput FROM GTSpan WHERE pipelineId = 'c10408c7-abde-5c19-b339-e8b1087c9b64' ORDER BY createdAt DESC LIMIT 10 FORMAT Pretty"
```

## Troubleshooting

### Common Issues

1. **Connection Refused**:

   - Ensure docker compose services are running: `docker compose ps`
   - Check port mappings in docker-compose.yml
   - Verify firewall settings

2. **Authentication Errors**:

   - Check API key format (should start with `gen_api_`)
   - Verify pipeline ID exists
   - Ensure API key has proper permissions

3. **No Data in Postgres**:

   - Check application logs: `docker compose logs app`
   - Verify OTEL endpoint is receiving data
   - Check SDK initialization is successful
   - Verify attributesMap structure (should be nested: `{test: {framework: "gentrace-sdk"}}`)

4. **No Data in ClickHouse**:

   - Data replication may be asynchronous - tests wait up to 2 minutes
   - Check task runner logs: `docker compose logs taskrunner`
   - Verify ClickHouse connection from the app
   - ClickHouse replication is eventually consistent and may take time to propagate

5. **Python SDK Compatibility Issues**:

   - The `gentrace-py` package has known compatibility issues with Python 3.13+
   - Use Python 3.12 or earlier
   - Install with `uv sync --pre` to get the alpha version

6. **ClickHouse Authentication**:
   - Local ClickHouse often runs without authentication
   - The Python test uses HTTP interface to handle empty passwords correctly
   - If you see connection errors, check your ClickHouse authentication settings

### Debug Commands

```bash
# Check service status
docker compose ps

# View application logs
docker compose logs app

# View task runner logs (handles ClickHouse replication)
docker compose logs taskrunner

# Connect to Postgres
docker compose exec postgres psql -U gentrace -d gentrace

# Connect to ClickHouse
docker compose exec clickhouse clickhouse-client
```

## Architecture Notes

### Data Flow with Gentrace SDK

```
Gentrace SDK interaction() → OpenTelemetry Spans → OTLP HTTP → /api/otel/v1/traces → bufferedInsertGTSpans → Postgres GTSpan → Task Runner → ClickHouse GTSpan
```

### Key Components

- **Gentrace SDK**: Provides `init()` and `interaction()` for easy instrumentation
- **OTEL Endpoint**: `/api/otel/v1/traces` accepts OTLP traces (JSON format)
- **Postgres GTSpan**: Primary storage with full trace data
- **ClickHouse GTSpan**: Analytics storage with replicated data
- **Task Runner**: Handles async replication to ClickHouse

### Database Schemas

**GTSpan Table** (both Postgres and ClickHouse):

- `id`, `traceId`, `threadId` - Identifiers
- `sourceOtelSpan`, `sourceOtelScope`, `sourceOtelResource` - Raw OTEL data
- `attributesMap` - Span attributes as nested JSON (e.g., `{test: {framework: "gentrace-sdk"}}`)
- `functionArgs`, `functionOutput` - Function call data as JSON strings
- `llmMessages`, `llmChoices` - LLM-specific data
- `pipelineId` - Associated pipeline ID
- `startTime`, `endTime` - Timing information

### Important Implementation Details

1. **Attribute Structure**: The `attributesMap` uses nested structure in Postgres JSONB, not dotted keys
2. **ClickHouse Data Types**: In ClickHouse, JSON fields are stored as String type
3. **Python HTTP Interface**: Python tests use HTTP interface for ClickHouse to handle authentication properly
4. **TypeScript Types**: TypeScript tests include proper Node.js type definitions
5. **Trace Flushing**: Tests use `beforeExit` handlers to ensure traces are flushed before process termination

## Contributing

To extend the tests:

1. Add new traced functions using SDK's `interaction()` wrapper
2. Add validation logic in `validate_postgres_ingestion()` or `validate_clickhouse_replication()`
3. Test with different SDK configurations and pipeline IDs
4. Ensure compatibility with both Python and TypeScript implementations

## SDK Versions

- **Python**: `gentrace-py` v1.0.0 alpha (install with `--pre` flag) - Note: Python 3.12 or earlier required
- **TypeScript/Node.js**: `@gentrace/core` v2.0.0+
