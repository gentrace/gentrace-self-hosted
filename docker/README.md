# Gentrace Self-Hosted Docker Setup

This directory contains Docker Compose configuration for running Gentrace in a self-hosted environment. The setup includes all necessary services for a complete Gentrace deployment.

## Prerequisites

- Docker Engine 20.10.0 or later
- Docker Compose v2.0.0 or later
- At least 4GB of RAM available
- At least 20GB of free disk space

## Services

The following services are included in this setup:

- **API Server**: REST API service (port 3000)
- **Web App**: Frontend application (port 3001)
- **WebSocket Server**: Real-time communication server (port 3002)
- **Task Runner**: Background job processor
- **Task Scheduler**: Job scheduling service
- **Databases**:
  - PostgreSQL (port 5432)
  - ClickHouse (ports 8123, 9000)
- **Message Queue**:
  - Kafka (ports 9092, 29092)
  - Kafka UI (port 8080)
  - Kafka Connect (port 8083)
- **Object Storage**:
  - MinIO (ports 9000, 9001)

## Quick Start

1. Clone the repository:

   ```bash
   git clone https://github.com/gentrace/gentrace-self-hosted.git
   cd gentrace-self-hosted/docker
   ```

2. Start the services:

   ```bash
   docker compose up -d
   ```

3. Monitor the logs:

   ```bash
   docker compose logs -f
   ```

4. Access the services:
   - Web App: http://localhost:3001
   - API: http://localhost:3000
   - Kafka UI: http://localhost:8080
   - MinIO Console: http://localhost:9001

## Environment Variables

Each service can be configured using environment variables. The default values are set in the `docker-compose.yml` file, but you can override them using a `.env` file.

## Data Persistence

All data is persisted using Docker volumes:

- `postgres_data`: PostgreSQL data
- `kafka_data`: Kafka data
- `minio_data`: MinIO object storage
- `clickhouse_data`: ClickHouse data

## Troubleshooting

1. If services fail to start, check the logs:

   ```bash
   docker compose logs [service-name]
   ```

2. To reset all data and start fresh:
   ```bash
   docker compose down -v
   docker compose up -d
   ```

## Security Notes

- Default credentials are set for development purposes only
- For production deployment:
  - Change all default passwords
  - Set up proper authentication
  - Configure SSL/TLS
  - Follow security best practices

## Support

For issues and support, please visit:
https://github.com/gentrace/gentrace-self-hosted/issues
