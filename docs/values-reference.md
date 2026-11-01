# Values Reference

Every field in `app/values.yaml`, with type and default.

## Overview

A complete, flat reference of every value accepted by the `app` chart. Use it to
look up a field's type, default, and meaning without opening `values.yaml`.

## When to use

Reach for this page when you know *what* you want to configure but not the exact
key, default, or shape. For task-oriented walkthroughs, start with
[Getting Started](getting-started.md) instead.

## Top-level

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `global.name` | string | `""` | Base name for all resources |
| `workload` | map | see below | The application workload |
| `service` | map | see below | Cluster Service |
| `persistence` | list | `[]` | Storage entries (see [Persistence](persistence.md)) |
| `serviceAccount` | map | see below | Service account |
| `podSecurityContext` | map | `{}` | Pod-level security context |
| `securityContext` | map | `{}` | Container-level security context |
| `nodeSelector` | map | `{}` | Node selector |
| `affinity` | map | `{}` | Pod affinity/anti-affinity |
| `tolerations` | list | `[]` | Pod tolerations |
| `imagePullSecrets` | list | `[]` | Image pull secrets |
| `external-secrets` | map | `{enabled: false}` | 1Password secrets subchart |
| `ingress` | map | `{enabled: false}` | Ingress subchart |

## `workload`

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `workload.enabled` | bool | `true` | Render the workload |
| `workload.type` | string | `Deployment` | `Deployment` or `StatefulSet` |
| `workload.annotations` | map | `{}` | Workload object annotations |
| `workload.image.repository` | string | `nginx` | Image repository |
| `workload.image.tag` | string | `1.25` | Image tag |
| `workload.image.pullPolicy` | string | `IfNotPresent` | Image pull policy |
| `workload.replicas` | int | `2` | Pod replicas |
| `workload.applicationPort` | int | `80` | App listening port |
| `workload.ports` | list | `[]` | Explicit container ports (`name`/`port`/`protocol`); `[]` = single `applicationPort` |
| `workload.command` | list | `[]` | Entrypoint override (`[]` = image default) |
| `workload.args` | list | `[]` | Args override (`[]` = image default) |
| `workload.pod.annotations` | map | `{}` | Pod template annotations |
| `workload.environment` | map | `{}` | Environment variables |
| `workload.volumes` | list | `[]` | Volume mounts (see [Volumes](volumes.md)) |
| `workload.extraContainers` | list | `[]` | Sidecars (see [Sidecars](sidecars.md)) |
| `workload.extraInitContainers` | list | `[]` | Init containers |
| `workload.resources` | map | `{requests:{cpu:300m,memory:512Mi}, limits:{cpu:1000m,memory:800Mi}}` | Resources |
| `workload.livenessProbe` | map | see [Probes](probes.md) | Liveness probe |
| `workload.readinessProbe` | map | see [Probes](probes.md) | Readiness probe |
| `workload.startupProbe` | map | see [Probes](probes.md) | Startup probe |
| `workload.strategy` | map | `{type: RollingUpdate, rollingUpdate:{maxUnavailable:1, maxSurge:1}}` | Deployment strategy |
| `workload.serviceName` | string | `""` | StatefulSet headless service name (default `<fullname>-cluster`) |
| `workload.updateStrategy` | map | `{type: RollingUpdate}` | StatefulSet update strategy |
| `workload.terminationGracePeriodSeconds` | int | `30` | StatefulSet grace period |
| `workload.service` | map | see below | StatefulSet headless service |

### `workload.service` (StatefulSet headless service)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `workload.service.annotations` | map | `{}` | Headless Service annotations |
| `workload.service.port` | int | `80` | Headless Service port |
| `workload.service.targetPort` | int | `80` | Headless Service target port |
| `workload.service.ports` | list | `[]` | Multi-port override (`name`/`port`/`targetPort`/`protocol`) |

## Probes

| Key | Type | Default (liveness / readiness / startup) |
|-----|------|------------------------------------------|
| `enabled` | bool | `true` / `true` / `true` |
| `type` | string | `http` / `http` / `http` |
| `path` | string | `/` / `/` / `/` |
| `port` | int/null | `null` / `null` / `null` |
| `custom` | bool | `false` / `false` / `false` |
| `spec` | map | `{}` / `{}` / `{}` |
| `initialDelaySeconds` | int | `0` / `0` / `5` |
| `periodSeconds` | int | `10` / `5` / `5` |
| `timeoutSeconds` | int | `1` / `1` / `3` |
| `failureThreshold` | int | `3` / `3` / `30` |
| `successThreshold` | int | `1` / `1` / `1` |

## `service` (top-level)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `service.enabled` | bool | `true` | Render the Service |
| `service.type` | string | `ClusterIP` | Service type |
| `service.port` | int | `80` | Service port |
| `service.targetPort` | int | `80` | Target port |
| `service.annotations` | map | `{}` | Service annotations |
| `service.ports` | list | `[]` | Multi-port list |

## `serviceAccount`

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `serviceAccount.create` | bool | `false` | Create a ServiceAccount |
| `serviceAccount.automount` | bool | `true` | Automount token |
| `serviceAccount.name` | string | `""` | Name (default `<fullname>`) |
| `serviceAccount.annotations` | map | `{}` | Annotations |

## Example

```yaml
global:
  name: "my-app"

workload:
  type: "Deployment"
  image:
    repository: nginx
    tag: "1.25"
  replicas: 2
  applicationPort: 8080
  ports:
    - name: http
      port: 8080
      protocol: TCP

service:
  type: ClusterIP
  port: 80
  targetPort: 8080
```

## Related

- [Workload](workload.md)
- [Probes](probes.md)
- [Persistence](persistence.md)
- [Ingress](ingress.md)
- [External Secrets](external-secrets.md)
