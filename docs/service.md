# Service

## Overview

The `service:` block (top-level) exposes your app to other pods in the cluster.

## When to use

Use it whenever anything needs to **reach your app by name** — other services,
ingress controllers, or your own tooling. It's enabled by default.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `service.enabled` | bool | `true` | Render the Service |
| `service.type` | string | `ClusterIP` | Service type |
| `service.port` | int | `80` | Service port |
| `service.targetPort` | int | `80` | Container port to forward to |
| `service.annotations` | map | `{}` | Service annotations |
| `service.ports` | list | `[]` | Optional multi-port list (overrides `port`/`targetPort`) |

Each entry in `service.ports` takes `name`, `port`, `targetPort`, `protocol`
(default `TCP`).

> **StatefulSet note:** a StatefulSet always also gets a headless service named
> `<fullname>-cluster` (or `workload.serviceName`). See [StatefulSet](statefulset.md).

## Example

```yaml
service:
  enabled: true
  type: ClusterIP
  port: 80
  targetPort: 8080
```

Multi-port:

```yaml
service:
  ports:
    - name: http
      port: 80
      targetPort: 8080
    - name: metrics
      port: 9102
      targetPort: 9102
```

## Related

- [Ingress](ingress.md)
- [StatefulSet](statefulset.md)
- [Values Reference](values-reference.md)
