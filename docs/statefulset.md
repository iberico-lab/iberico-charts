# StatefulSet

## Overview

Set `workload.type: "StatefulSet"` to run stateful apps with **stable pod
identity** and **per-pod storage**.

## When to use

Choose a StatefulSet when your app needs:

- A stable network identity (predictable pod names: `app-0`, `app-1`, …).
- Its own storage volume per pod.
- Ordered, graceful rollout/scale-down.

Typical fits: **databases, message queues, clustered systems**. For stateless
apps, use the default Deployment — see [Workload](workload.md).

## StatefulSet-specific values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `workload.serviceName` | string | `""` | Headless service name (default `<fullname>-cluster`) |
| `workload.updateStrategy` | map | `{type: RollingUpdate}` | Pod update strategy |
| `workload.terminationGracePeriodSeconds` | int | `30` | Grace period on termination |
| `workload.service.port` | int | `80` | Headless service port |
| `workload.service.targetPort` | int | `80` | Headless service target port |
| `workload.service.ports` | list | `[]` | Optional multi-port list |
| `workload.service.annotations` | map | `{}` | Headless service annotations |

`persistence:` entries become `volumeClaimTemplates` (one PVC per pod). See
[Persistence](persistence.md).

## Example

```yaml
workload:
  enabled: true
  type: "StatefulSet"
  image:
    repository: postgres
    tag: "16"
  applicationPort: 5432
  replicas: 1
  serviceName: ""              # defaults to <fullname>-cluster
  updateStrategy:
    type: RollingUpdate
  terminationGracePeriodSeconds: 30

persistence:
  - name: data
    size: 10Gi
    mountPath: /var/lib/postgresql/data
    accessModes: ["ReadWriteOnce"]
```

## Generated resources

| Resource | Name |
|----------|------|
| StatefulSet | `<fullname>` |
| Headless Service | `workload.serviceName` or `<fullname>-cluster` |
| Service (if `service.enabled`) | `<fullname>` |
| PVCs (per pod) | `<volumeClaimTemplate name>-<fullname>-<ordinal>` |

## Related

- [Workload](workload.md)
- [Persistence](persistence.md)
- [Service](service.md)
