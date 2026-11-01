# Sidecars & Init Containers

## Overview

Add extra containers alongside your main app: **init containers** run before the
app starts, **sidecars** run next to it for the app's whole life.

## When to use

| Kind | When to use |
|------|-------------|
| **Init containers** | Prepare the environment first — wait for a database, run migrations, fetch config. |
| **Sidecars** | Add a helper to the pod — log shipper, metrics exporter, service mesh proxy. |

Both are rendered **verbatim** into the pod, so any valid container spec works.
Each entry **must define `name`** or the render fails loudly.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `workload.extraContainers` | list | `[]` | Sidecar containers (verbatim) |
| `workload.extraInitContainers` | list | `[]` | Init containers (verbatim) |

## Example

```yaml
workload:
  extraInitContainers:
    - name: wait-for-db
      image: busybox:1.36
      command: ["sh", "-c", "until nc -z db 5432; do sleep 2; done"]
  extraContainers:
    - name: metrics-exporter
      image: prom/statsd-exporter:latest
      ports:
        - name: metrics
          containerPort: 9102
```

## Related

- [Workload](workload.md)
- [Probes](probes.md)
