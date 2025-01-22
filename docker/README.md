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

## Environment Variables

The following tables list all required environment variables for each service:

### App & API Service

| Variable                    | Description                       | Example/Default                                          |
| --------------------------- | --------------------------------- | -------------------------------------------------------- |
| CLICKHOUSE_DATABASE         | ClickHouse database name          | gentrace                                                 |
| CLICKHOUSE_HOST             | ClickHouse hostname               | clickhouse                                               |
| CLICKHOUSE_PASSWORD         | ClickHouse password               | gentrace123                                              |
| CLICKHOUSE_PORT             | ClickHouse port                   | 8123                                                     |
| CLICKHOUSE_PROTOCOL         | ClickHouse protocol               | http                                                     |
| CLICKHOUSE_USER             | ClickHouse username               | default                                                  |
| DATABASE_URL                | Full PostgreSQL connection string | postgresql://gentrace:gentrace123@postgres:5432/gentrace |
| ENVIRONMENT                 | Deployment environment identifier | production                                               |
| JWT_SECRET                  | JWT token secret key              | Generated using: openssl rand -base64 32                 |
| KAFKA_BROKER                | Kafka broker hostname             | kafka                                                    |
| KAFKA_PORT                  | Kafka broker port                 | 9092                                                     |
| NEXT_PUBLIC_SELF_HOSTED     | Self-hosted deployment flag       | true                                                     |
| NEXT_PUBLIC_SELF_HOSTED_TLS | TLS enablement status             | true                                                     |
| NODE_ENV                    | Environment mode                  | production, development                                  |
| PORT                        | Service port number               | 3000                                                     |
| POSTGRES_DB                 | PostgreSQL database name          | gentrace                                                 |
| POSTGRES_PASSWORD           | PostgreSQL password               | gentrace123                                              |
| POSTGRES_USER               | PostgreSQL username               | gentrace                                                 |
| PRISMA_FIELD_ENCRYPTION_KEY | Prisma field encryption key       | Generated from https://cloak.47ng.com/                   |
| PUBLIC_HOSTNAME             | Public hostname for the service   | api.yourdomain.com                                       |
| STORAGE_ACCESS_KEY_ID       | Object storage access key         | your-access-key                                          |
| STORAGE_BUCKET              | Object storage bucket name        | gentrace-public                                          |
| STORAGE_ENDPOINT            | Object storage endpoint URL       | https://storage.googleapis.com                           |
| STORAGE_FORCE_PATH_STYLE    | Path style access setting         | true                                                     |
| STORAGE_REGION              | Object storage region             | us-central1                                              |
| STORAGE_SECRET_ACCESS_KEY   | Object storage secret key         | your-secret-key                                          |

### WebSocket Server

| Variable                    | Description                           | Example/Default                                          |
| --------------------------- | ------------------------------------- | -------------------------------------------------------- |
| CLICKHOUSE_DATABASE         | ClickHouse database name              | gentrace                                                 |
| CLICKHOUSE_HOST             | ClickHouse hostname                   | clickhouse                                               |
| CLICKHOUSE_PASSWORD         | ClickHouse password                   | gentrace123                                              |
| CLICKHOUSE_PORT             | ClickHouse port                       | 8123                                                     |
| CLICKHOUSE_PROTOCOL         | ClickHouse protocol                   | http                                                     |
| CLICKHOUSE_USER             | ClickHouse username                   | default                                                  |
| DATABASE_URL                | Full PostgreSQL connection string     | postgresql://gentrace:gentrace123@postgres:5432/gentrace |
| ENVIRONMENT                 | Deployment environment identifier     | production                                               |
| JWT_SECRET                  | JWT token secret key                  | Generated using: openssl rand -base64 32                 |
| KAFKA_BROKER                | Kafka broker hostname                 | kafka                                                    |
| KAFKA_PORT                  | Kafka broker port                     | 9092                                                     |
| NEXT_PUBLIC_SELF_HOSTED     | Self-hosted deployment flag           | true                                                     |
| NEXT_PUBLIC_SELF_HOSTED_TLS | TLS enablement status                 | true                                                     |
| NODE_ENV                    | Environment mode                      | production, development                                  |
| PORT                        | WebSocket service port number         | 3001                                                     |
| POSTGRES_DB                 | PostgreSQL database name              | gentrace                                                 |
| POSTGRES_PASSWORD           | PostgreSQL password                   | gentrace123                                              |
| POSTGRES_USER               | PostgreSQL username                   | gentrace                                                 |
| PRISMA_FIELD_ENCRYPTION_KEY | Prisma field encryption key           | Generated from https://cloak.47ng.com/                   |
| PUBLIC_HOSTNAME             | Public hostname for WebSocket service | ws.yourdomain.com                                        |
| STORAGE_ACCESS_KEY_ID       | Object storage access key             | your-access-key                                          |
| STORAGE_BUCKET              | Object storage bucket name            | gentrace-public                                          |
| STORAGE_ENDPOINT            | Object storage endpoint URL           | https://storage.googleapis.com                           |
| STORAGE_FORCE_PATH_STYLE    | Path style access setting             | true                                                     |
| STORAGE_REGION              | Object storage region                 | us-central1                                              |
| STORAGE_SECRET_ACCESS_KEY   | Object storage secret key             | your-secret-key                                          |

### Task Runner

| Variable                    | Description                       | Example/Default                                          |
| --------------------------- | --------------------------------- | -------------------------------------------------------- |
| CLICKHOUSE_DATABASE         | ClickHouse database name          | gentrace                                                 |
| CLICKHOUSE_HOST             | ClickHouse hostname               | clickhouse                                               |
| CLICKHOUSE_PASSWORD         | ClickHouse password               | gentrace123                                              |
| CLICKHOUSE_PORT             | ClickHouse port                   | 8123                                                     |
| CLICKHOUSE_PROTOCOL         | ClickHouse protocol               | http                                                     |
| CLICKHOUSE_USER             | ClickHouse username               | default                                                  |
| DATABASE_URL                | Full PostgreSQL connection string | postgresql://gentrace:gentrace123@postgres:5432/gentrace |
| ENVIRONMENT                 | Deployment environment identifier | production                                               |
| JWT_SECRET                  | JWT token secret key              | Generated using: openssl rand -base64 32                 |
| KAFKA_BROKER                | Kafka broker hostname             | kafka                                                    |
| KAFKA_PORT                  | Kafka broker port                 | 9092                                                     |
| NEXT_PUBLIC_SELF_HOSTED     | Self-hosted deployment flag       | true                                                     |
| NEXT_PUBLIC_SELF_HOSTED_TLS | TLS enablement status             | true                                                     |
| NODE_ENV                    | Environment mode                  | production, development                                  |
| POSTGRES_DB                 | PostgreSQL database name          | gentrace                                                 |
| POSTGRES_PASSWORD           | PostgreSQL password               | gentrace123                                              |
| POSTGRES_USER               | PostgreSQL username               | gentrace                                                 |
| PRISMA_FIELD_ENCRYPTION_KEY | Prisma field encryption key       | Generated from https://cloak.47ng.com/                   |
| PUBLIC_HOSTNAME             | Public hostname for the service   | taskrunner.yourdomain.com                                |
| STORAGE_ACCESS_KEY_ID       | Object storage access key         | your-access-key                                          |
| STORAGE_BUCKET              | Object storage bucket name        | gentrace-public                                          |
| STORAGE_ENDPOINT            | Object storage endpoint URL       | https://storage.googleapis.com                           |
| STORAGE_FORCE_PATH_STYLE    | Path style access setting         | true                                                     |
| STORAGE_REGION              | Object storage region             | us-central1                                              |
| STORAGE_SECRET_ACCESS_KEY   | Object storage secret key         | your-secret-key                                          |

### Task Scheduler

| Variable                    | Description                       | Example/Default                                          |
| --------------------------- | --------------------------------- | -------------------------------------------------------- |
| CLICKHOUSE_DATABASE         | ClickHouse database name          | gentrace                                                 |
| CLICKHOUSE_HOST             | ClickHouse hostname               | clickhouse                                               |
| CLICKHOUSE_PASSWORD         | ClickHouse password               | gentrace123                                              |
| CLICKHOUSE_PORT             | ClickHouse port                   | 8123                                                     |
| CLICKHOUSE_PROTOCOL         | ClickHouse protocol               | http                                                     |
| CLICKHOUSE_USER             | ClickHouse username               | default                                                  |
| DATABASE_URL                | Full PostgreSQL connection string | postgresql://gentrace:gentrace123@postgres:5432/gentrace |
| ENVIRONMENT                 | Deployment environment identifier | production                                               |
| JWT_SECRET                  | JWT token secret key              | Generated using: openssl rand -base64 32                 |
| KAFKA_BROKER                | Kafka broker hostname             | kafka                                                    |
| KAFKA_PORT                  | Kafka broker port                 | 9092                                                     |
| NEXT_PUBLIC_SELF_HOSTED     | Self-hosted deployment flag       | true                                                     |
| NEXT_PUBLIC_SELF_HOSTED_TLS | TLS enablement status             | true                                                     |
| NODE_ENV                    | Environment mode                  | production, development                                  |
| POSTGRES_DB                 | PostgreSQL database name          | gentrace                                                 |
| POSTGRES_PASSWORD           | PostgreSQL password               | gentrace123                                              |
| POSTGRES_USER               | PostgreSQL username               | gentrace                                                 |
| PRISMA_FIELD_ENCRYPTION_KEY | Prisma field encryption key       | Generated from https://cloak.47ng.com/                   |
| PUBLIC_HOSTNAME             | Public hostname for the service   | scheduler.yourdomain.com                                 |
| STORAGE_ACCESS_KEY_ID       | Object storage access key         | your-access-key                                          |
| STORAGE_BUCKET              | Object storage bucket name        | gentrace-public                                          |
| STORAGE_ENDPOINT            | Object storage endpoint URL       | https://storage.googleapis.com                           |
| STORAGE_FORCE_PATH_STYLE    | Path style access setting         | true                                                     |
| STORAGE_REGION              | Object storage region             | us-central1                                              |
| STORAGE_SECRET_ACCESS_KEY   | Object storage secret key         | your-secret-key                                          |

### Admin Configuration

| Variable       | Description                 | Example/Default            |
| -------------- | --------------------------- | -------------------------- |
| ADMIN_EMAIL    | Initial admin user email    | admin@yourdomain.com       |
| ADMIN_NAME     | Initial admin user name     | Admin User                 |
| ADMIN_PASSWORD | Initial admin user password | your-secure-admin-password |

## Environment Setup

To set up your environment variables:

For Unix-based systems (Linux/Mac):

```bash
./environment/setup-env.sh
```

These scripts will help you generate secure values and create a `.env` file with all necessary configurations.

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
