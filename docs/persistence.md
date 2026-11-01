# Persistence

## Overview

`persistence:` (top-level, **not** under `workload:`) declares durable storage
for your app. The chart wires it into the pod automatically.

## When to use

Use it whenever your app must **keep data across restarts** — databases, uploads,
caches that matter. For read-only config or secrets, use [Volumes](volumes.md)
instead.

Behavior depends on workload type:

| `workload.type` | What the chart creates |
|-----------------|------------------------|
| **Deployment** | Standalone `PersistentVolumeClaim` per entry |
| **StatefulSet** | `volumeClaimTemplates` — one PVC per pod |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `persistence[].name` | string | — | Volume name (also the mount name) |
| `persistence[].size` | string | — | Storage size (e.g. `20Gi`) |
| `persistence[].mountPath` | string | — | Where to mount in the container |
| `persistence[].accessModes` | list | `[ReadWriteMany]` | Access modes |
| `persistence[].storageClassName` | string | — | Storage class |
| `persistence[].readOnly` | bool | `false` | Mount read-only |

> **opendrive** storage class adds rclone annotations automatically.

## Example

```yaml
persistence:
  - name: data
    size: 20Gi
    mountPath: /var/lib/data
    accessModes: ["ReadWriteOnce"]
    storageClassName: "fast-ssd"
```

## Related

- [Volumes](volumes.md)
- [StatefulSet](statefulset.md)
- [Values Reference](values-reference.md)
