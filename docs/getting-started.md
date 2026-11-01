# Getting Started

## Overview

The `app` chart deploys one application (a Deployment or a StatefulSet) plus an
optional Service, Ingress, and secrets. You configure it with a small values file.

## When to use

Use this chart for **any** application you want to run on Kubernetes. If your app
needs a container, a port, and maybe storage or ingress, this chart already
supports it. You rarely need to write raw Kubernetes YAML.

## Steps

### 1. Create a values file

```yaml
# values-myapp.yaml
global:
  name: "my-app"          # drives all resource names

workload:
  enabled: true
  type: "Deployment"
  image:
    repository: nginx
    tag: "1.25"
  applicationPort: 80
  replicas: 2
```

### 2. Resolve bundled subcharts

```bash
helm dependency update ./charts/app
```

### 3. Install

```bash
helm install my-app ./charts/app -f values-myapp.yaml
```

### 4. Preview before installing (recommended)

```bash
helm template my-app ./charts/app -f values-myapp.yaml
```

## Example

A minimal, complete values file for an app listening on port 8080:

```yaml
global:
  name: "my-app"

workload:
  enabled: true
  type: "Deployment"
  image:
    repository: nginx
    tag: "1.25"
  replicas: 2
  applicationPort: 8080

service:
  enabled: true
  port: 80
  targetPort: 8080
```

## What gets created

| Resource | Condition |
|----------|-----------|
| Deployment (or StatefulSet) | `workload.enabled: true` (default) |
| Service (ClusterIP :80) | `service.enabled: true` (default) |
| Ingress | `ingress.enabled: true` (off by default) |
| ExternalSecret | `external-secrets.enabled: true` (off by default) |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `global.name` | string | `""` | Base name for all resources |
| `workload.enabled` | bool | `true` | Render the workload |
| `workload.type` | string | `Deployment` | `Deployment` or `StatefulSet` |
| `workload.image.repository` | string | `nginx` | Container image |
| `workload.image.tag` | string | `1.25` | Image tag |
| `workload.applicationPort` | int | `80` | Port the app listens on |
| `workload.replicas` | int | `2` | Pod replicas |

## Related

- [Workload](workload.md) — full workload options
- [Service](service.md) — networking
- [Values Reference](values-reference.md) — every field
