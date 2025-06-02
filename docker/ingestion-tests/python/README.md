# Gentrace Ingestion Tests - Python

This directory contains Python tests for validating the Gentrace self-hosted ingestion pipeline using the official Gentrace SDK.

## Setup

This project uses [uv](https://github.com/astral-sh/uv) for Python dependency management.

### Python Version Requirement

**Important**: The `gentrace-py` package has compatibility issues with Python 3.13+. Please use Python 3.12 or earlier.

```bash
# Use Python 3.12
uv venv -p python3.12
```

### Install dependencies

```bash
# Install with pre-release support (gentrace-py is in alpha)
uv sync --pre
```

### Run tests

```bash
# Run directly with Python
uv run python test_ingestion_pipeline.py
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

This test uses the official Gentrace Python SDK (`gentrace-py` v1.0.0 alpha) which provides:

- `gentrace.init()` - Initialize the SDK with API key and base URL
- `gentrace.interaction()` - Decorator to wrap functions with OpenTelemetry tracing
- `gentrace.GentraceSampler` - Custom sampler for OpenTelemetry
- `gentrace.GentraceSpanProcessor` - Span processor for baggage management

## Implementation Details

### ClickHouse Connection

The test uses HTTP interface for ClickHouse queries instead of the `clickhouse-driver` to handle authentication properly, especially when ClickHouse is configured without a password.

### Attribute Structure

The test validates nested attribute structures in `attributesMap`:

```python
attrs.get("test", {}).get("framework") == "gentrace-sdk"
```

### Known Issues

1. **Python 3.13+ Compatibility**: The `gentrace-py` package has typing compatibility issues with Python 3.13+. Use Python 3.12 or earlier.

2. **ClickHouse Authentication**: If using empty passwords, the HTTP interface is more reliable than the native driver.

## Development

### Code formatting

```bash
uv run black .
uv run ruff check .
```

### Type checking

```bash
uv run mypy .
```

## Troubleshooting

If you encounter import errors with `gentrace-py`:

1. Ensure you're using Python 3.12 or earlier
2. Install with `uv sync --pre` to get the alpha version
3. Check that `typing_extensions` is properly installed
