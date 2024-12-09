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
- Grafana: Metrics visualization
- Jaeger: Distributed tracing

You can access the Kiali dashboard using:

```bash
istioctl dashboard kiali
```

# Database Credentials Configuration

## ClickHouse Credentials

Before deploying the Helm chart, you need to create a Kubernetes secret containing the ClickHouse credentials and configuration:

1. Create a secret manifest file (e.g., `clickhouse-secret.yaml`):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: clickhouse-credentials
type: Opaque
stringData:
  CLICKHOUSE_USER: your-username
  CLICKHOUSE_PASSWORD: your-password
  users.xml: |
    <?xml version="1.0"?>
    <clickhouse>
        <users>
            <default>
                <password>your-password</password>
                <networks>
                    <ip>::/0</ip>
                </networks>
                <profile>default</profile>
                <quota>default</quota>
            </default>
        </users>
    </clickhouse>
```

2. Apply the secret:

```bash
kubectl apply -f clickhouse-secret.yaml
```

3. Update your values.yaml to reference the secret:

```yaml
secrets:
  clickhouse:
    name: clickhouse-credentials
```

Note: Make sure to replace 'your-username' and 'your-password' with secure credentials. The password in users.xml should match the CLICKHOUSE_PASSWORD value.

## PostgreSQL Credentials

You'll also need to create a secret for PostgreSQL credentials:

1. Create a secret manifest file (e.g., `postgres-secret.yaml`):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
type: Opaque
stringData:
  POSTGRES_USER: your-postgres-username
  POSTGRES_PASSWORD: your-postgres-password
```

2. Apply the secret:

```bash
kubectl apply -f postgres-secret.yaml
```

3. Update your values.yaml to reference the secret:

```yaml
secrets:
  postgres:
    name: postgres-credentials
```

Note: The PostgreSQL database name is set to 'gentrace' by default in the StatefulSet configuration. If you need to change this, you'll need to modify the StatefulSet template.

## Kafka Credentials

For Kafka configuration:

1. Create a secret manifest file (e.g., `kafka-secret.yaml`):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: kafka-credentials
type: Opaque
stringData:
  kafka_server_jaas.conf: |
    KafkaServer {
      org.apache.kafka.common.security.plain.PlainLoginModule required
      username="admin"
      password="admin-secret";
    };
```

2. Apply the secret:

```bash
kubectl apply -f kafka-secret.yaml
```

3. Update your values.yaml to reference the secret:

```yaml
secrets:
  kafka:
    name: kafka-credentials
```

Note: The current Kafka configuration uses PLAINTEXT protocol without authentication. The JAAS configuration is included but not actively used. For production environments, consider enabling SASL authentication.

## Object Storage Credentials

Create a secret for object storage credentials:

1. Create a secret manifest file (e.g., `object-storage-secret.yaml`):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: object-storage-credentials
type: Opaque
stringData:
  # Add your object storage credentials here
```

2. Apply the secret:

```bash
kubectl apply -f object-storage-secret.yaml
```

3. Update your values.yaml to reference the secret:

```yaml
secrets:
  object-storage:
    name: object-storage-credentials
```
