# `app` Chart Values Schema Reference

Authoritative source: `charts/app/values.yaml`. This document mirrors it. When in
doubt, read `charts/app/values.yaml` — it is the source of truth.

## Top-level keys

| Key                  | Type    | Purpose                                                        |
|----------------------|---------|----------------------------------------------------------------|
| `global.name`        | string  | Application name; drives all resource names (via helm-helpers). |
| `workload`           | object  | The unified Deployment/StatefulSet config (see below).          |
| `service`            | object  | ClusterIP/NodePort/LoadBalancer service for external access.    |
| `serviceAccount`     | object  | ServiceAccount creation + automount.                            |
| `persistence`        | list    | PVCs (Deployment) or volumeClaimTemplates (StatefulSet).        |
| `podSecurityContext` | object  | Pod-level security context.                                     |
| `securityContext`    | object  | Main container security context.                                |
| `nodeSelector`       | object  | Pod node selector.                                              |
| `affinity`           | object  | Pod affinity/anti-affinity.                                     |
| `tolerations`        | list    | Pod tolerations.                                                |
| `imagePullSecrets`   | list    | Image pull secrets.                                             |
| `external-secrets`   | object  | External Secrets subchart config.                               |
| `ingress`            | object  | Ingress subchart config.                                        |

> `global.nameOverride` / `global.fullnameOverride` are also honored by
> helm-helpers for name overrides.

## `workload:` schema

| Field                             | Type    | Default              | Notes |
|-----------------------------------|---------|----------------------|-------|
| `enabled`                         | bool    | `true`               | Renders the workload at all. |
| `type`                            | string  | `"Deployment"`       | `Deployment` or `StatefulSet`. |
| `annotations`                     | object  | `{}`                 | Workload metadata annotations. |
| `image.repository`                | string  | `nginx`              | |
| `image.tag`                       | string  | `"1.25"`             | |
| `image.pullPolicy`                | string  | `IfNotPresent`       | |
| `replicas`                        | int     | `2`                  | |
| `applicationPort`                 | int     | `80`                 | Default port for container + probes. |
| `ports`                           | list    | `[]`                 | Explicit container ports (`name`/`port`/`protocol`); `[]` = single `applicationPort`. |
| `command`                         | list    | `[]`                 | Empty = inherit image ENTRYPOINT. |
| `args`                            | list    | `[]`                 | Empty = inherit image CMD. |
| `pod.annotations`                 | object  | `{}`                 | Pod-template annotations. |
| `environment`                     | object  | `{}`                 | `key: value` → container `env`. |
| `volumes`                         | list    | `[]`                 | See Volumes below. |
| `extraContainers`                 | list    | `[]`                 | Verbatim sidecars; `name` required. |
| `extraInitContainers`             | list    | `[]`                 | Verbatim init containers; `name` required. |
| `resources`                       | object  | requests/limits      | Standard K8s resources. |
| `livenessProbe`                   | object  | see Probes           | |
| `readinessProbe`                  | object  | see Probes           | |
| `startupProbe`                    | object  | see Probes           | |
| `strategy`                        | object  | RollingUpdate        | Deployment only. |
| `serviceName`                     | string  | `""`                 | StatefulSet headless svc name; default `<app>-cluster`. |
| `updateStrategy`                  | object  | RollingUpdate        | StatefulSet only. |
| `terminationGracePeriodSeconds`   | int     | `30`                 | StatefulSet only. |
| `service.annotations`             | object  | `{}`                 | Headless-service annotations (StatefulSet). |
| `service.port`                    | int     | `80`                 | |
| `service.targetPort`              | int     | `80`                 | |
| `service.ports`                   | list    | `[]`                 | Multi-port override (name/port/targetPort/protocol). |

> Note: `workload.service.*` configures the **headless** service for
> StatefulSets. The **regular** external service is configured by the top-level
> `service:` key.

## Probe schema

Every probe (`livenessProbe`, `readinessProbe`, `startupProbe`) shares this shape.
Partial overrides are safe: any omitted field inherits its default via Helm map
coalescing.

| Field                 | Default (liveness) | readiness | startup | Notes |
|-----------------------|--------------------|-----------|---------|-------|
| `enabled`             | `true`             | `true`    | `true`  | Render the probe. |
| `type`                | `"http"`           | `"http"`  | `"http"`| `http` \| `tcp` \| `grpc` \| `exec`. |
| `path`                | `"/"`              | `"/"`     | `"/"`   | HTTP path. |
| `port`                | `null`             | `null`    | `null`  | `null` → `applicationPort`. |
| `host`                | –                  | –         | –       | Optional (http/tcp). |
| `scheme`              | –                  | –         | –       | Optional HTTP/HTTPS (http). |
| `httpHeaders`         | –                  | –         | –       | Optional list (http). |
| `command`             | –                  | –         | –       | Required when `type: exec`. |
| `custom`              | `false`            | `false`   | `false` | Emit `spec` verbatim. |
| `spec`                | –                  | –         | –       | Raw probe block when `custom: true`. |
| `initialDelaySeconds` | `0`                | `0`       | `5`     | |
| `periodSeconds`       | `10`               | `5`       | `5`     | |
| `timeoutSeconds`      | `1`                | `1`       | `3`     | |
| `failureThreshold`    | `3`                | `3`       | `30`    | |
| `successThreshold`    | `1`                | `1`       | `1`     | |

A probe is only rendered when `enabled: true` **and** (for custom probes) `spec`
is non-empty — an empty/null probe block is safely skipped.

## Volumes (`workload.volumes[]`)

Each entry has `name`, `mountPath`, optional `readOnly`, and exactly one source:

```yaml
- name: app-config
  mountPath: /etc/config
  readOnly: true
  configMap:
    name: my-app-config
    items: [{ key: config.yaml, path: config.yaml }]

- name: tls-certs
  mountPath: /etc/ssl
  secret:
    secretName: my-app-tls
    items: [{ key: tls.crt, path: tls.crt }]

- name: shared
  mountPath: /mnt/shared
  persistentVolumeClaim:
    claimName: shared-data-pvc

- name: tmp
  mountPath: /tmp
  emptyDir: {}
```

## Persistence (`persistence[]`)

| Field              | Required | Default        | Notes |
|--------------------|----------|----------------|-------|
| `name`             | yes      | –              | PVC suffix. |
| `size`             | yes      | –              | e.g. `20Gi`. |
| `accessModes`      | no       | `[ReadWriteMany]` | K8s access modes. |
| `storageClassName` | no       | cluster default| `opendrive` triggers rclone annotations. |
| `mountPath`        | yes      | –              | Container mount path. |
| `readOnly`         | no       | `false`        | |
| `annotations`      | no       | `{}`           | |
| `rclone`           | no       | –              | `storagePath`, `umask`, `annotations` (opendrive only). |

- **Deployment**: standalone PVC named `<fullname>-<name>`.
- **StatefulSet**: `volumeClaimTemplates` entry named `<name>` (one per pod).

## `service:` (top-level)

| Field        | Default     | Notes |
|--------------|-------------|-------|
| `enabled`    | `true`      | |
| `type`       | `ClusterIP` | |
| `port`       | `80`        | |
| `targetPort` | `80`        | |
| `ports`      | `[]`        | Optional multi-port list. |
| `annotations`| `{}`        | |

## `serviceAccount:`

| Field       | Default | Notes |
|-------------|---------|-------|
| `create`    | `false` | Create a dedicated SA. |
| `automount` | `true`  | Mount SA token. |
| `name`      | –       | Override generated name. |

## Subchart value blocks

```yaml
external-secrets:
  enabled: false          # condition for the subchart
  onepassword: {}         # see charts/external-secrets/values.yaml

ingress:
  enabled: false          # condition for the subchart
  ingresses: []           # see charts/ingress/values.yaml
```

See `subchart-pattern.md` for how these are wired.
