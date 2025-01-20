# Gentrace Self-Hosted Deployment Options

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/gentrace-self-hosted)](https://artifacthub.io/packages/search?repo=gentrace-self-hosted)

This repository contains multiple deployment options for self-hosting Gentrace. Each option is designed to accommodate different infrastructure requirements and preferences.

## Available Deployment Methods

### 1. Kubernetes with Helm

- Full Kubernetes deployment using Helm charts
- Includes service mesh integration with Istio for mTLS between containers
- Configurable storage classes and database credentials
- Suitable for production environments

### 2. Docker Compose

- Simplified deployment using Docker Compose
- Great for development and testing
- Minimal infrastructure requirements
- Easy setup and teardown
- See the [Docker Setup Guide](./docker/README.md) to get started

## Getting Started

Choose the deployment method that best suits your needs:

- For Kubernetes deployment, see the [Helm Chart Documentation](./kubernetes/helm-chart/README.md)
- For Docker Compose deployment, see the [Docker Setup Guide](./docker/README.md)

## Requirements

Requirements vary based on the chosen deployment method. See individual documentation for specific details.

## Support

For support with any deployment method:

- Email [support@gentraceai.com](mailto:support@gentraceai.com)
- Refer to our [documentation](https://gentrace.ai/docs)
