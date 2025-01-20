# Gentrace Self-Hosted Docker Setup

⚠️ **Development Only**: This Docker setup is for local development and testing. Not suitable for production use.

This directory contains everything you need to run Gentrace locally using Docker Compose.

## Features

- One-command setup with Docker Compose
- Pre-configured services (Kafka, PostgreSQL, ClickHouse)
- Built-in monitoring with Kafka UI
- Local file storage with MinIO
- Automatic service discovery and networking

## Prerequisites

- Docker Engine 20.10.0+
- Docker Compose v2.0.0+
- 4GB RAM minimum
- 20GB disk space minimum

## Quick Start

1. Start the services:

   ```bash
   docker compose up -d
   ```

2. Access the services:
   - Web App: http://localhost:3000
   - Kafka UI: http://localhost:8080
   - MinIO Console: http://localhost:9001 (credentials: minioadmin/minioadmin)

## Services Overview

Core Services:

- Web App & API (port 3000)
- WebSocket Server (port 3001)
- Task Runner & Scheduler

Infrastructure:

- PostgreSQL (port 5432)
- ClickHouse (port 8123)
- Kafka (ports 9092, 29092)
- MinIO (ports 9000, 9001)

## Troubleshooting

View logs for a specific service:

```bash
docker compose logs -f [service-name]
```

Reset all data and start fresh:

```bash
docker compose down -v
docker compose up -d
```

## Deployment notes

1. Change all default passwords in `.env`
2. Set secure values for `JWT_SECRET` and `PRISMA_FIELD_ENCRYPTION_KEY`
3. Configure proper SSL/TLS
4. Set appropriate admin credentials
