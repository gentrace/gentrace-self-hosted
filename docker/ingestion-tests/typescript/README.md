# Gentrace Ingestion Tests - TypeScript/Node.js

This directory contains TypeScript tests for validating the Gentrace self-hosted ingestion pipeline.

## Setup

### Install dependencies

```bash
npm install
```

This will install all required dependencies including TypeScript type definitions for Node.js.

### Run tests

```bash
# Run with tsx (TypeScript execution)
npm test

# Or run directly with tsx
npx tsx test-ingestion-node.ts
```

## Test Configuration

The test can be configured using environment variables:

- `GENTRACE_BASE_URL` - Base URL of the Gentrace instance (default: http://localhost:3000/api)
- `POSTGRES_HOST` - PostgreSQL host (default: localhost)
- `POSTGRES_PORT` - PostgreSQL port (default: 5432)
- `POSTGRES_DB` - PostgreSQL database (default: gentrace)
- `POSTGRES_USER` - PostgreSQL user (default: gentrace)
- `POSTGRES_PASSWORD` - PostgreSQL password (default: gentrace123)
- `CLICKHOUSE_HOST` - ClickHouse host (default: localhost)
- `CLICKHOUSE_PORT` - ClickHouse port (default: 8123)
- `CLICKHOUSE_DB` - ClickHouse database (default: default)
- `CLICKHOUSE_USER` - ClickHouse user (default: default)
- `CLICKHOUSE_PASSWORD` - ClickHouse password (default: empty string)
- `GENTRACE_API_KEY` - API key for authentication
- `ORGANIZATION_ID` - Organization ID for test data
- `PIPELINE_ID` - Pipeline ID for test data (default: c10408c7-abde-5c19-b339-e8b1087c9b64)

## Dependencies

This test uses:

- TypeScript for type safety
- tsx for TypeScript execution
- Gentrace SDK (`@gentrace/core`) for instrumentation
- OpenTelemetry SDK for Node.js
- PostgreSQL client (pg) with types
- ClickHouse client
- Pino for structured logging with pretty printing
- @types/node for Node.js type definitions

## Development

The test is written in TypeScript (`test-ingestion-node.ts`) and uses:

- Interfaces for configuration and database row types
- Async/await for better error handling
- Type-safe database queries
- Class-based structure for better organization
- `beforeExit` handler to ensure traces are flushed properly
- Pino logger for structured logging with emojis

## Implementation Details

- **Attribute Structure**: The test validates nested attribute structures in `attributesMap`
- **Content-Type**: Uses `application/json` for OTLP exporter (matching the SDK's format)
- **Trace Flushing**: Uses `process.on('beforeExit')` to ensure traces are flushed before exit
- **ClickHouse Queries**: Queries the GTSpan table with proper JSON parsing for attributesMap
- **Logging**: Uses Pino with pretty printing for structured, colorized logs

## TypeScript Configuration

The project includes a `tsconfig.json` with:

- Target: ES2022
- Module: CommonJS
- Strict mode enabled
- Node.js types included
- DOM library for console support
