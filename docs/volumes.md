# Volumes

## Overview

`workload.volumes` mounts **existing** Kubernetes objects into your container:
ConfigMaps, Secrets, `emptyDir` scratch space, or a PVC you manage yourself.

## When to use

| Source | When to use |
|--------|-------------|
| `configMap` | Mount config files or environment config from a ConfigMap. |
| `secret` | Mount credentials/certs from a Secret. |
| `emptyDir` | Temporary scratch space shared by containers, discarded on pod exit. |
| `persistentVolumeClaim` | Attach a PVC that you create and manage outside the chart. |

For storage the **chart should create**, use [Persistence](persistence.md).

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `volumes[].name` | string | — | Volume name |
| `volumes[].mountPath` | string | — | Mount path in the container |
| `volumes[].readOnly` | bool | `false` | Mount read-only |
| `volumes[].configMap.name` | string | — | ConfigMap to mount |
| `volumes[].configMap.items` | list | — | Optional key→path items |
| `volumes[].secret.secretName` | string | — | Secret to mount |
| `volumes[].secret.items` | list | — | Optional key→path items |
| `volumes[].emptyDir` | map | — | `{}` for a default emptyDir |
| `volumes[].persistentVolumeClaim.claimName` | string | — | Existing PVC name |

Exactly one source key is used per entry.

## Example

```yaml
workload:
  volumes:
    - name: config
      mountPath: /etc/config
      readOnly: true
      configMap:
        name: my-app-config
    - name: scratch
      mountPath: /tmp/work
      emptyDir: {}
```

## Related

- [Persistence](persistence.md)
- [External Secrets](external-secrets.md)
- [Values Reference](values-reference.md)
