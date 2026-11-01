# Workload

## Overview

The `workload:` block defines your application: what image to run, how many
replicas, which port, and whether it is a **Deployment** or a **StatefulSet**.

## When to use

- **Deployment** (default) — stateless apps: web servers, APIs, workers. Pods are
  interchangeable.
- **StatefulSet** — stateful apps needing stable identity and per-pod storage:
  databases, queues, clusters. See [StatefulSet](statefulset.md).

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `workload.enabled` | bool | `true` | Render the workload |
| `workload.type` | string | `Deployment` | `Deployment` or `StatefulSet` |
| `workload.image.repository` | string | `nginx` | Container image repository |
| `workload.image.tag` | string | `1.25` | Image tag |
| `workload.image.pullPolicy` | string | `IfNotPresent` | Image pull policy |
| `workload.replicas` | int | `2` | Number of pod replicas |
| `workload.applicationPort` | int | `80` | Port the app listens on |
| `workload.command` | list | `[]` | Override entrypoint (`[]` = image default) |
| `workload.args` | list | `[]` | Override args (`[]` = image default) |
| `workload.annotations` | map | `{}` | Annotations on the workload object |
| `workload.pod.annotations` | map | `{}` | Annotations on the pod template |
| `workload.environment` | map | `{}` | Environment variables (`KEY: value`) |
| `workload.resources` | map | see below | CPU/memory requests and limits |
| `workload.strategy` | map | RollingUpdate | Deployment rollout strategy |

Default resources:

```yaml
workload:
  resources:
    requests: { cpu: 300m, memory: 512Mi }
    limits:   { cpu: 1000m, memory: 800Mi }
```

## Example

```yaml
workload:
  enabled: true
  type: "Deployment"
  image:
    repository: ghcr.io/example/app
    tag: "1.2.3"
  replicas: 3
  applicationPort: 8080
  environment:
    LOG_LEVEL: "info"
  command: ["/bin/sh"]
  args: ["-c", "exec my-app"]
```

## Related

- [StatefulSet](statefulset.md)
- [Probes](probes.md)
- [Sidecars & Init Containers](sidecars.md)
