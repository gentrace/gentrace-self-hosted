# Container Registry Proxy Setup

This guide explains how to configure Gentrace self-hosted to work with container registry proxies for Quay.io and Docker Hub.

## Overview

Gentrace self-hosted pulls container images from two registries:
- **Quay.io** - For Gentrace-specific images (`gentrace/core`, `gentrace/kafka-connect-clickhouse`)
- **Docker Hub** - For third-party images (`postgres`, `clickhouse`, `kafka`, etc.)

In environments with restricted internet access, you can configure proxy URLs to route image pulls through your organization's container registry proxies.

## Configuration

### 1. Environment Variables

Set these variables in your `.env` file:

```bash
# Quay.io proxy (for Gentrace images)
QUAY_IMAGE_URL_PREFIX="your-proxy.company.com/quay.io"

# Docker Hub proxy (for third-party images)  
DOCKER_REGISTRY_URL_PREFIX="your-proxy.company.com"
```

### 2. How It Works

The docker-compose.yml uses these variables with different patterns:

**For Quay images:**
```yaml
image: ${QUAY_IMAGE_URL_PREFIX:-quay.io}/gentrace/core:production
```
- Default: `quay.io/gentrace/core:production`
- With proxy: `your-proxy.company.com/quay.io/gentrace/core:production`

**For Docker Hub images:**
```yaml
image: ${DOCKER_REGISTRY_URL_PREFIX:+$DOCKER_REGISTRY_URL_PREFIX/}postgres:15.3
```
- Default: `postgres:15.3`
- With proxy: `your-proxy.company.com/postgres:15.3`

### 3. Example Configuration

```bash
# Example .env configuration for corporate proxy
QUAY_IMAGE_URL_PREFIX="registry.corp.example.com/quay.io"
DOCKER_REGISTRY_URL_PREFIX="registry.corp.example.com"
```

This will pull:
- `registry.corp.example.com/quay.io/gentrace/core:production`
- `registry.corp.example.com/postgres:15.3`
- `registry.corp.example.com/clickhouse/clickhouse-server:24.8`

## Affected Services

**Quay.io images:**
- `app` - Main Gentrace application
- `websocket-server` - WebSocket server
- `taskrunner` - Background task processor
- `taskscheduler` - Task scheduler
- `kafka-connect` - Kafka Connect with ClickHouse

**Docker Hub images:**
- `postgres` - PostgreSQL database
- `kafka` - Apache Kafka
- `kafka-ui` - Kafka management UI
- `minio` - Object storage
- `clickhouse` - ClickHouse analytics database

## Testing

After configuring the proxy URLs:

1. Update your `.env` file with the proxy settings
2. Run `docker-compose pull` to test image pulling
3. Start the stack with `docker-compose up -d`

If images fail to pull, verify:
- Your proxy URLs are correct
- The proxy has access to both Quay.io and Docker Hub
- Authentication is properly configured for your proxy

## Authentication

By default, both Quay.io and Docker Hub registry containers are **unauthenticated**. If your organization's proxy requires authentication to access these registries, you'll need to configure Docker authentication.

### Setting Up Authentication

If your proxy requires authentication, follow the [Docker login guide](https://docs.docker.com/reference/cli/docker/login/) to authenticate with your proxy registry:

```bash
# Authenticate with your proxy registry
docker login your-proxy.company.com

# Or specify credentials directly
docker login your-proxy.company.com -u username -p password
```

### Authentication Methods

1. **Interactive login** (recommended for development):
   ```bash
   docker login your-proxy.company.com
   ```

2. **Environment variables** (for CI/CD):
   ```bash
   export DOCKER_USERNAME=your-username
   export DOCKER_PASSWORD=your-password
   echo $DOCKER_PASSWORD | docker login your-proxy.company.com -u $DOCKER_USERNAME --password-stdin
   ```

3. **Docker config file** (persistent):
   - Credentials are stored in `~/.docker/config.json` after successful login
   - This file is automatically used for subsequent pulls

### Troubleshooting Authentication

If you encounter authentication errors:

- **401 Unauthorized**: Check your credentials and ensure they're valid for the proxy
- **403 Forbidden**: Verify your account has access to pull from Quay.io and Docker Hub through the proxy
- **Network errors**: Ensure your proxy is accessible and properly configured

**Note**: Authentication is handled at the Docker daemon level, so once configured, it applies to all `docker pull` and `docker-compose` operations.
