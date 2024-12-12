# Gentrace Helm Chart

This Helm chart deploys a complete Gentrace self-hosted environment on Kubernetes. It includes all necessary components for running Gentrace, including:

- Gentrace API Server
- Gentrace Web Application Frontend
- Gentrace WebSocket Server
- PostgreSQL Database
- ClickHouse Analytics Database
- Kafka Message Queue
- Object Storage Integration (optional MinIO deployment)
- Service Mesh (Istio) Configuration

## Prerequisites

Before installing this chart, you'll need:

- Kubernetes 1.19+
- Helm 3.0+
- Istio service mesh installed (see Istio Configuration section below)
- A configured storage class (see Storage Class Configuration section below)
- Access to pull container images
- Configured secrets (see example in `kubernetes/example-secrets/`)

## Quick Start

1. Create a `values.yaml` file with your configuration:

# Storage Class Configuration

You must specify a storage class policy for your Kubernetes cluster before deploying this Helm chart. The storage class should have an appropriate reclaim policy based on your data retention needs.

Here's an example storage class configuration with a "Retain" policy that preserves volumes after PVC deletion:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gentrace-storage
provisioner: kubernetes.io/gce-pd # Change based on your cloud provider
parameters:
  type: gp3 # Storage type, change as needed
  fsType: ext4
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

# Istio Configuration

Before deploying this Helm chart, you'll need to install and configure Istio. Follow these steps:

1. Install Istioctl by following the [official Istio getting started guide](https://istio.io/latest/docs/setup/getting-started/). You can download and install it using:

```bash
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
```

2. Install Istio with the demo profile to get helpful utilities like Kiali for visualizing your service mesh:

```bash
istioctl install --set profile=demo
```

3. Enable automatic sidecar injection for the namespace that you've deployed the Gentrace chart into:

```bash
kubectl label namespace default istio-injection=enabled
```

The demo profile includes several useful tools:

- Kiali: Service mesh observability dashboard
- Prometheus: Metrics collection

You can access the Kiali dashboard using:

```bash
istioctl dashboard kiali
```

# Database Credentials Configuration

Before deploying the Helm chart, you'll need to create several Kubernetes secrets. Below are the required secrets and their configurations:

## Admin Credentials

Create a secret for the admin user:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: admin-credentials
type: Opaque
stringData:
  email: "admin@yourdomain.com"
  name: "Admin User"
  password: "your-secure-admin-password"
```

## ClickHouse Credentials

Create a secret for ClickHouse configuration:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: clickhouse-credentials
type: Opaque
stringData:
  CLICKHOUSE_PORT: "8123"
  CLICKHOUSE_PROTOCOL: "http"
  CLICKHOUSE_DATABASE: "gentrace"
  CLICKHOUSE_USER: "default"
  CLICKHOUSE_PASSWORD: "gentrace123"
  CLICKHOUSE_HOST: "clickhouse" # Don't change this!
```

## JWT Secret

Create a secret for JWT authentication:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: jwt-secret
type: Opaque
stringData:
  # Generate using: openssl rand -base64 32
  JWT_SECRET: "your-very-long-secure-random-jwt-secret-key"
```

## Kafka Configuration

Create a secret for Kafka settings:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: kafka-credentials
type: Opaque
stringData:
  KAFKA_BROKER: "kafka"
  KAFKA_PORT: "9092"
```

## Object Storage Configuration

Create a secret for object storage access:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: object-storage-credentials
type: Opaque
stringData:
  STORAGE_ACCESS_KEY_ID: "your-access-key"
  STORAGE_SECRET_ACCESS_KEY: "your-secret-key"
  STORAGE_ENDPOINT: "https://storage.googleapis.com"
  STORAGE_BUCKET: "gentrace-public"
  STORAGE_REGION: "us-central1" # Required even for MinIO
  STORAGE_FORCE_PATH_STYLE: "true"
```

## PostgreSQL Configuration

Create a secret for PostgreSQL credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
type: Opaque
stringData:
  POSTGRES_USER: "gentrace"
  POSTGRES_PASSWORD: "gentrace123"
  POSTGRES_DB: "gentrace"
  DATABASE_URL: "postgresql://gentrace:gentrace123@postgres:5432/gentrace"
```

## Prisma Field Encryption

Create a secret for Prisma field encryption:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: prisma-field-encryption-secret
type: Opaque
stringData:
  # Generate a new key at: https://cloak.47ng.com/
  PRISMA_FIELD_ENCRYPTION_KEY: "<your-new-key>"
```

After creating all the secrets, apply them to your cluster:

```bash
kubectl apply -f your-secrets.yaml
```

Update your values.yaml to reference these secrets:

```yaml
secrets:
  admin:
    name: admin-credentials
  clickhouse:
    name: clickhouse-credentials
  jwt:
    name: jwt-secret
  kafka:
    name: kafka-credentials
  objectStorage:
    name: object-storage-credentials
  postgres:
    name: postgres-credentials
  prismaFieldEncryption:
    name: prisma-field-encryption-secret
```
