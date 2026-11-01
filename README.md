# 🐽 Iberico Charts

A collection of Helm charts for managing external secrets, ingress, and application deployments with 1Password Connect
integration.

> 📚 **Full documentation lives in [`docs/`](docs/index.md)** — per-feature guides,
> "When to use" sections, and copy-paste examples. Start there.

---

## 📁 Repository Layout

```text
charts/
  app/               # Umbrella application chart (depends on the charts below)
  external-secrets/  # ExternalSecret / SecretStore subchart (1Password Connect)
  ingress/           # Tailscale + Traefik ingress subchart
  helm-helpers/      # Shared library chart (template helpers)
docs/                # Per-feature documentation (start at docs/index.md)
examples/            # Copy-paste values files for the app chart
.github/
  configs/           # ct.yaml, cr.yaml, lintconf.yaml (chart-testing / releaser)
  workflows/         # Lint + release pipelines
Makefile             # make deps | lint | template | examples | clean
```

Subcharts reference each other as siblings (`file://../<name>`), so they must
stay together under `charts/`.

---

## ⚡ Quick Start

Deploy a simple application with minimal configuration:

```bash
helm dependency update ./charts/app

helm install my-app ./charts/app \
  --set global.name=my-app \
  --set workload.image.repository=nginx \
  --set workload.image.tag=alpine
```

Creates:

* ✅ Deployment with 2 replicas
* ✅ ClusterIP service on port 80

Ingress and external secrets are **off by default** — enable them when you need
them (see [`docs/ingress.md`](docs/ingress.md) and
[`docs/external-secrets.md`](docs/external-secrets.md)).

---

## Features

### 🔐 External Secrets Integration

Load secrets from **1Password (default)** or other providers.

* **Unified model**: Secrets can be injected as **environment variables** or mounted as **files**.
* **Automatic SecretStore**: Managed per-app (or disabled if you bring your own).

**Example: env vars from secrets**

```yaml
external-secrets:
  enabled: true
  onepassword:
    enabled: true
    secrets:
      - envVars:
          - secretKey: "credentials-database"
            mappings:
              DB_PASSWORD: password
              DB_USER: username
              API_KEY: api-key
```

**Example: files from secrets**

```yaml
external-secrets:
  enabled: true
  onepassword:
    enabled: true
    secrets:
      - files:
          - secretKey: "certificates-tls"
            mappings:
              tls.crt: certificate
              tls.key: private-key
```

---

## 🌐 Ingress Management

Three ingress types with automatic TLS + Homepage integration.

### Ingress Types (at a glance)

| Type               | Controller | TLS           | Auth    |
|--------------------|------------|---------------|---------|
| `internal`         | Tailscale  | ❌             | N/A     |
| `public`           | Traefik    | Let’s Encrypt | ❌       |
| `public-protected` | Traefik    | Let’s Encrypt | ✅ (SSO) |

> Ingress is **off by default** (`ingress.enabled: false`). Enable it and list the
> ingresses you want. See [`docs/ingress.md`](docs/ingress.md) for details.

---

### 🏠 Internal Ingress (Tailscale Only)

* **Purpose**: Expose apps only to your Tailscale network
* **Use Case**: Internal services, dev tools, dashboards
* **Features**:

    * No external internet access
    * Uses Tailscale ingress controller
    * Requires `ingress.enabled: true`

```yaml
ingress:
  enabled: true
  ingresses:
    - name: "my-app"
      type: "internal"
      # No host needed (internal-only)
```

---

### 🔓 Public Ingress (Unauthenticated)

* **Purpose**: Expose apps publicly on the internet
* **Use Case**: Public websites, APIs, docs
* **Features**:

    * Uses Traefik ingress controller
    * Automatic Let’s Encrypt TLS
    * No authentication required

```yaml
ingress:
  enabled: true
  ingresses:
    - name: "my-app"
      type: "public"
      host: "my-app.mycompany.com"
      homepage:
        name: "My App"
        description: "Public application"
        group: "Applications"
```

---

### 🔐 Public-Protected Ingress (SSO)

* **Purpose**: Expose apps publicly but require authentication
* **Use Case**: Admin panels, internal dashboards, sensitive apps
* **Features**:

    * Uses Traefik ingress controller
    * Automatic Let’s Encrypt TLS
    * Auth via `network-sso` middleware

```yaml
ingress:
  enabled: true
  ingresses:
    - name: "my-app"
      type: "public-protected"
      host: "my-app-auth.mycompany.com"
```

---

### 📋 Homepage Integration

All ingress types automatically generate [Homepage](https://gethomepage.dev) entries.

* **Automatic detection**: No manual config required
* **Grouped by type**: Internal, Public, Public-Protected
* **Customizable**: Override names, descriptions, and icons

**Default internal example:**

```yaml
ingress:
  enabled: true
  ingresses:
    - name: "my-app"
      type: "internal"
      # Shows up in Homepage under "Internal"
```

**Custom example:**

```yaml
ingress:
  enabled: true
  ingresses:
    - name: "my-app"
      type: "public"
      host: "my-app.mycompany.com"
      homepage:
        name: "My Custom App"
        description: "Custom description"
        group: "Custom Group"
        icon: "custom-icon"
```

---

## 🚀 Workload Configuration

A single `workload:` block drives both **Deployment** and **StatefulSet** rendering,
selected via `workload.type` (`Deployment` or `StatefulSet`).

```yaml
workload:
  enabled: true
  type: "Deployment"          # or "StatefulSet"
  image:
    repository: nginx
    tag: "1.25"
    pullPolicy: IfNotPresent
  replicas: 2
  applicationPort: 80
```

### Container `command` / `args`

Override the main container's entrypoint and arguments. Empty lists (`[]`) keep the
image defaults.

```yaml
workload:
  command: ["/bin/sh"]        # empty [] = inherit image ENTRYPOINT
  args: ["-c", "echo hi"]     # empty [] = inherit image CMD
```

### Extra (Sidecar) Containers

`workload.extraContainers` renders **verbatim** into the pod's `containers` list.
Each entry **must define `name`** (render fails loud otherwise).

```yaml
workload:
  extraContainers:
    - name: metrics-exporter
      image: prom/statsd-exporter:latest
      ports:
        - name: metrics
          containerPort: 9102
```

### Extra Init Containers

`workload.extraInitContainers` renders **verbatim** into the pod's `initContainers`
list. Each entry **must define `name`**.

```yaml
workload:
  extraInitContainers:
    - name: wait-for-db
      image: busybox:1.36
      command: ["sh", "-c", "until nc -z db 5432; do sleep 2; done"]
```

---

## 💾 Multi-PVC Persistence

Support for multiple PVCs per app with flexible configs.

| Field              | Description                               | Required | Default |
|--------------------|-------------------------------------------|----------|---------|
| `name`             | PVC name suffix (`<fullname>-<name>`)      | ✅        | -       |
| `size`             | Storage size (`10Gi`, `100G`)             | ✅        | -       |
| `accessModes`      | K8s access modes                          | ✅        | -       |
| `storageClassName` | Storage class name                        | ❌        | Default |
| `mountPath`        | Container mount path                      | ✅        | -       |
| `readOnly`         | Mount as read-only                        | ❌        | `false` |
| `annotations`      | PVC annotations                           | ❌        | `{}`    |

**Example: multiple PVCs**

```yaml
persistence:
  - name: data
    size: 20Gi
    accessModes: [ "ReadWriteOnce" ]
    storageClassName: "fast-ssd"
    mountPath: /var/lib/mysql
  - name: logs
    size: 5Gi
    accessModes: [ "ReadWriteOnce" ]
    storageClassName: "standard"
    mountPath: /var/log/mysql
```

---

## 🏥 Health Checks

Every probe (`livenessProbe`, `readinessProbe`, `startupProbe`) supports **partial overrides**:
any field you omit inherits its `values.yaml` default via Helm's native map coalescing.
You only need to specify the fields you want to change.

```yaml
workload:
  livenessProbe:
    type: "tcp"          # Restart only if process dies
  readinessProbe:
    type: "http"         # Stop traffic if busy
    path: "/healthz"
  startupProbe:
    type: "http"         # Handle slow boot
    path: "/healthz"
```

**Example: override a single field** (everything else keeps its default):

```yaml
workload:
  readinessProbe:
    periodSeconds: 15    # only this changes; type/path/port stay default
```

### Probe Roles

* 🔴 **Liveness**: process alive? (HTTP `/` by default)
* 🟡 **Readiness**: can handle traffic? (HTTP `/`)
* 🟢 **Startup**: slow init apps (HTTP `/`)

### Probe Fields

| Field                  | Description                                                | Default              |
|------------------------|------------------------------------------------------------|----------------------|
| `enabled`              | Render the probe at all                                    | `true`               |
| `type`                 | Handler: `http`, `tcp`, `grpc`, or `exec`                  | `http`               |
| `path`                 | HTTP path (type `http`)                                    | `/`                  |
| `port`                 | Port for the handler                                       | `workload.applicationPort` |
| `host`                 | Optional host (http/tcp)                                   | –                    |
| `scheme`               | Optional scheme `HTTP`/`HTTPS` (http)                      | –                    |
| `httpHeaders`          | Optional HTTP headers list (http)                          | –                    |
| `command`              | Command list — **required** for type `exec`                | –                    |
| `custom`               | Emit `spec` verbatim, ignoring the fields above            | `false`              |
| `spec`                 | Raw probe block, used only when `custom: true`             | –                    |
| `initialDelaySeconds`  | Delay before first probe                                   | `0` (startup: `5`)   |
| `periodSeconds`        | Probe interval                                             | `10` (readiness/startup: `5`) |
| `timeoutSeconds`       | Probe timeout                                              | `1` (startup: `3`)   |
| `successThreshold`     | Successes required to be healthy                           | `1`                  |
| `failureThreshold`     | Failures before action                                     | `3` (startup: `30`)  |

### Custom Probes

Set `custom: true` and provide a raw `spec` to bypass the structured fields entirely
(useful for handlers the chart does not model, e.g. `grpc` with extra options):

```yaml
workload:
  livenessProbe:
    custom: true
    spec:
      httpGet:
        path: /live
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 20
```

> ⚠️ **Fail-loud validation**: an unsupported `type`, or `type: exec` without a
> `command`, aborts the render with a clear error instead of emitting a broken probe.

---

## 📦 Volume Management

Volumes can come from **ConfigMaps, Secrets, PVCs, or emptyDir**.

Here’s a **mixed example**:

```yaml
workload:
  volumes:
    # Mount a ConfigMap as files under /etc/config (read-only)
    - name: "app-config"
      configMap:
        name: "my-app-config"
      mountPath: "/etc/config"
      readOnly: true

    # Mount a Secret as files under /etc/ssl (read-only)
    - name: "tls-certs"
      secret:
        secretName: "my-app-tls"
      mountPath: "/etc/ssl"
      readOnly: true

    # Mount an existing PersistentVolumeClaim (PVC) for shared storage
    - name: "shared-storage"
      persistentVolumeClaim:
        claimName: "shared-data-pvc"
      mountPath: "/mnt/shared"

    # Create an emptyDir (ephemeral, deleted when Pod stops)
    - name: "temp-files"
      emptyDir: { }
      mountPath: "/tmp"
```
