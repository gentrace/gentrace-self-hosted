# Quay Image Pull Secret

The Gentrace team will provide you with a `quay-image-pull-secret.yaml` file, which contains the Kubernetes secret manifest required for pulling images from our repository. The name of the secret will also be `quay-image-pull-secret`. Modify your Helm chart values to properly reflect this new secret.

```yaml
image:
    pullPolicy: Always
    pullSecretName: "quay-image-pull-secret"
```

If they have not provided it yet, please request it at [support@gentrace.ai](mailto:support@gentrace.ai).

[Image showing Quay image pull secret process](https://share.cleanshot.com/bMqVNhfc)