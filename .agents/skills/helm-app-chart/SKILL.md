---
name: helm-app-chart
description: >
  Use when you need to create, migrate, or deploy an application to Kubernetes
  using the reusable `app` Helm chart in the iberico-charts repository. Covers the
  `workload:` values schema (image, replicas, command/args, extraContainers,
  extraInitContainers, probes, environment, volumes, persistence, service,
  ingress, external-secrets, Deployment vs StatefulSet), the subchart
  composition pattern, and validation with helm dependency update / lint /
  template. Trigger on requests like "make a Helm chart for X", "deploy X with
  the app chart", or "add a subchart".
version: 1.0.0
author: Iberico Lab
license: MIT
keywords:
  - helm
  - kubernetes
  - app-chart
  - deployment
  - statefulset
  - subchart
---

# Making a Helm Chart with the `app` Chart

## What the `app` chart is

The `app` chart (`charts/app/`) is a **reusable "Lego block" application
chart**. It already bundles the pieces every app needs, so consumers **add
features by toggling values — not by adding charts**:

| Bundled subchart    | Purpose                                   | Enabled by                       |
|---------------------|-------------------------------------------|----------------------------------|
| `helm-helpers`      | Naming, labels, selectors                 | always (no toggle)               |
| `external-secrets`  | 1Password secrets → env vars / files      | `external-secrets.enabled: true` |
| `ingress`           | Tailscale internal + Traefik public ingress | `ingress.enabled: true`        |

A single `workload:` block drives either a **Deployment** or a **StatefulSet**
(`workload.type`). Do **not** copy or fork the chart per app — create a values
file and install `charts/app/`.

> Authoritative schema lives in `charts/app/values.yaml`. Always read it before
> authoring values; do not rely on memory.

## How to consume it

1. Create a values file (e.g. `values-myapp.yaml`) using the `workload:` schema.
2. Point the image, port, and any optional features.
3. Validate, then install.

Minimal values file:

```yaml
global:
  name: "my-app"          # drives all resource names (helm-helpers)

workload:
  enabled: true
  type: "Deployment"      # or "StatefulSet"
  image:
    repository: nginx
    tag: "1.25"
  applicationPort: 80
```

Install:

```bash
helm dependency update ./charts/app
helm install my-app ./charts/app -f values-myapp.yaml
```

## Key features

All fields below live under `workload:` unless noted. Full field-by-field
reference: `references/values-schema.md`.

### Image, replicas, port

```yaml
workload:
  image:
    repository: ghcr.io/example/app
    tag: "1.2.3"
    pullPolicy: IfNotPresent
  replicas: 3
  applicationPort: 8080
```

### `command` / `args`

Override the main container entrypoint/args. Empty `[]` inherits the image
defaults.

```yaml
workload:
  command: ["/bin/sh"]
  args: ["-c", "exec my-app"]
```

### `extraContainers` (sidecars) and `extraInitContainers`

Rendered **verbatim** into the pod. Each entry **MUST define `name`** — the
render fails loud otherwise.

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

### Probes (partial override)

`livenessProbe`, `readinessProbe`, `startupProbe` support **partial overrides**:
omitted fields inherit their `charts/app/values.yaml` default via Helm native map
coalescing — set only what changes.

```yaml
workload:
  readinessProbe:
    periodSeconds: 15          # everything else stays default
  livenessProbe:
    type: "tcp"                # http | tcp | grpc | exec
  startupProbe:
    enabled: false             # disable a probe
```

Handler types and the `exec` requirement:

```yaml
workload:
  livenessProbe:
    type: "exec"
    command: ["cat", "/tmp/healthy"]   # REQUIRED when type: exec
```

Custom raw probe — set `custom: true` and provide `spec` (emitted verbatim):

```yaml
workload:
  livenessProbe:
    custom: true
    spec:
      httpGet:
        path: /live
        port: 8080
      initialDelaySeconds: 10
```

### Environment, volumes, persistence

```yaml
workload:
  environment:
    LOG_LEVEL: "info"          # simple key: value map
  volumes:                     # configMap | secret | emptyDir | persistentVolumeClaim
    - name: config
      mountPath: /etc/config
      readOnly: true
      configMap:
        name: my-app-config

persistence:                   # top-level, NOT under workload
  - name: data
    size: 20Gi
    accessModes: ["ReadWriteOnce"]
    storageClassName: "fast-ssd"
    mountPath: /var/lib/data
```

`persistence` behavior differs by type:

- **Deployment** → chart creates standalone `PersistentVolumeClaim` objects.
- **StatefulSet** → entries become `volumeClaimTemplates` (one PVC per pod).

### Service

```yaml
service:                       # top-level
  enabled: true
  type: ClusterIP
  port: 80
  targetPort: 8080
  # ports: []                  # optional multi-port list (name/port/targetPort/protocol)
```

StatefulSets always also render a headless service (`<app>-cluster`, or
`workload.serviceName`).

### Ingress

```yaml
ingress:
  enabled: true
  ingresses:
    - name: "my-app"
      type: "internal"         # internal | public | public-protected
      host: ""                 # required for public types
      servicePort: 80
      homepage:                # optional Homepage entry
        name: "My App"
        group: "Applications"
```

### External secrets (1Password)

```yaml
external-secrets:
  enabled: true
  onepassword:
    enabled: true
    refreshInterval: "10m"
    clusterSecretStoreRef: onepassword-cluster
    secrets:
      - envVars:
          - secretKey: "credentials-database"
            mappings:
              DATABASE_PASSWORD: password
        files:
          - secretKey: "certificates-tls"
            mappings:
              tls.crt: cert
```

- `envVars` are injected into the main container automatically (`envFrom`).
- `files` are mounted at `/etc/secrets/onepassword/`.

### Deployment vs StatefulSet

Set `workload.type`. StatefulSet adds `serviceName`, `updateStrategy`,
`terminationGracePeriodSeconds`, and per-pod `volumeClaimTemplates`. Use
StatefulSet for stateful workloads (databases, queues) needing stable identity
and per-pod storage.

## Conventions

- **Sensible defaults**: every feature has a working default in `charts/app/values.yaml`.
- **Partial overrides**: rely on Helm's native map coalescing — never restate
  defaults you are not changing.
- **Fail-loud**: unsupported probe `type`, `type: exec` without `command`, and
  `extraContainers`/`extraInitContainers` without `name` abort the render with a
  clear error rather than emitting a broken manifest.
- **`name` required** on every extra/init container.
- Details: `references/conventions.md`.

## The subchart pattern

`app` is a **parent chart** that composes subcharts declared in `charts/app/Chart.yaml`
(`dependencies:` with `file://../<name>` repositories, gated by a `condition`).
Consumers enable a bundled subchart by toggling its values — they never add
charts themselves. To add a *new* reusable capability, create a sibling chart
and wire it into `charts/app/Chart.yaml`. Full walkthrough:
`references/subchart-pattern.md`.

## Validate before deploying

```bash
helm dependency update ./charts/app     # resolve/refresh bundled subcharts
helm lint ./charts/app -f values-myapp.yaml
helm template my-app ./charts/app -f values-myapp.yaml   # render locally, inspect output
```

`helm template` is the fastest way to confirm your values produce the expected
Deployment/StatefulSet, Service, Ingress, and ExternalSecret objects.

## References

- `references/values-schema.md` — complete `workload:` + top-level field reference.
- `references/subchart-pattern.md` — composing subcharts and adding a new one.
- `references/conventions.md` — defaults, partial overrides, fail-loud rules.
- `charts/app/values.yaml` — authoritative schema (read this first).
- `examples/` (numbered, tested in CI), `README.md`, `docs/` — worked examples.
