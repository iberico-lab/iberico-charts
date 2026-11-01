# StatefulSet Configuration Guide

> 📚 See also [`docs/statefulset.md`](docs/statefulset.md) for the per-feature
> reference, and [`docs/index.md`](docs/index.md) for all documentation.

## Quick Start

To enable StatefulSet, set `workload.type: "StatefulSet"` in your values file.

## Basic Configuration

```yaml
global:
  name: "my-app"

workload:
  enabled: true
  type: "StatefulSet"
  image:
    repository: my-app
    tag: "latest"
  replicas: 1
  applicationPort: 8080
  
  # Environment variables
  environment:
    MY_VAR: "value"
  
  # Resources
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"

persistence:
  - name: data
    size: 10Gi
    storageClassName: "opendrive"
    mountPath: /data
```

## Common Use Cases

### 1. Database (PostgreSQL)
```yaml
workload:
  enabled: true
  type: "StatefulSet"
  image:
    repository: postgres
    tag: "15"
  applicationPort: 5432
  environment:
    POSTGRES_DB: "mydb"
    POSTGRES_USER: "postgres"
    POSTGRES_PASSWORD: "password"
    PGDATA: "/var/lib/postgresql/data/pgdata"

persistence:
  - name: data
    size: 20Gi
    accessModes: ["ReadWriteOnce"]
    storageClassName: "opendrive"
    mountPath: /var/lib/postgresql/data
```

### 2. Cache (Redis)
```yaml
workload:
  enabled: true
  type: "StatefulSet"
  image:
    repository: redis
    tag: "7-alpine"
  applicationPort: 6379
  environment:
    REDIS_PASSWORD: "password"

persistence:
  - name: data
    size: 10Gi
    accessModes: ["ReadWriteOnce"]
    storageClassName: "opendrive"
    mountPath: /data
```

### 3. Message Queue (RabbitMQ)
```yaml
workload:
  enabled: true
  type: "StatefulSet"
  image:
    repository: rabbitmq
    tag: "3-management"
  applicationPort: 5672
  environment:
    RABBITMQ_DEFAULT_USER: "admin"
    RABBITMQ_DEFAULT_PASS: "password"

persistence:
  - name: data
    size: 10Gi
    accessModes: ["ReadWriteOnce"]
    storageClassName: "opendrive"
    mountPath: /var/lib/rabbitmq
```

### 4. Search Engine (Elasticsearch)
```yaml
workload:
  enabled: true
  type: "StatefulSet"
  image:
    repository: docker.elastic.co/elasticsearch/elasticsearch
    tag: "8.11.0"
  replicas: 3
  applicationPort: 9200
  environment:
    node.name: "${POD_NAME}"
    cluster.name: "elasticsearch-cluster"
    discovery.seed_hosts: "elasticsearch-headless"
    cluster.initial_master_nodes: "elasticsearch-0,elasticsearch-1,elasticsearch-2"
    "ES_JAVA_OPTS": "-Xms1g -Xmx1g"

persistence:
  - name: data
    size: 100Gi
    accessModes: ["ReadWriteOnce"]
    storageClassName: "opendrive"
    mountPath: /usr/share/elasticsearch/data
```

## Container `command` / `args`

Override the main container's entrypoint and arguments. Empty lists (`[]`) keep the
image defaults.

```yaml
workload:
  type: "StatefulSet"
  command: ["/bin/sh"]        # empty [] = inherit image ENTRYPOINT
  args: ["-c", "exec my-app"] # empty [] = inherit image CMD
```

## Extra (Sidecar) and Init Containers

`workload.extraContainers` and `workload.extraInitContainers` render **verbatim** into
the pod's `containers` and `initContainers` lists. Each entry **must define `name`**
(the render fails loud otherwise).

```yaml
workload:
  type: "StatefulSet"

  # Init containers run before the main container
  extraInitContainers:
    - name: wait-for-db
      image: busybox:1.36
      command: ["sh", "-c", "until nc -z db 5432; do sleep 2; done"]

  # Sidecars run alongside the main container
  extraContainers:
    - name: metrics-exporter
      image: prom/statsd-exporter:latest
      ports:
        - name: metrics
          containerPort: 9102
```

## External Secrets Integration

```yaml
external-secrets:
  enabled: true
  onepassword:
    enabled: true
    secrets:
      - envVars:
          - secretKey: "app-secrets"
            mappings:
              DATABASE_PASSWORD: db-password
              API_KEY: api-key
        files:
          - secretKey: "app-config"
            mappings:
              config.yaml: app-config-file

workload:
  enabled: true
  type: "StatefulSet"
  # Environment variables from external secrets will be automatically injected
  # Files will be mounted at /etc/secrets/onepassword/
```

## Multiple Volumes

```yaml
persistence:
  - name: data
    size: 50Gi
    accessModes: ["ReadWriteOnce"]
    storageClassName: "opendrive"
    mountPath: /data
  - name: logs
    size: 10Gi
    accessModes: ["ReadWriteOnce"]
    storageClassName: "opendrive"
    mountPath: /var/log
  - name: config
    size: 5Gi
    accessModes: ["ReadWriteOnce"]
    storageClassName: "opendrive"
    mountPath: /etc/config
```

## Health Checks

Each probe supports **partial overrides**: omitted fields inherit their `values.yaml`
default via Helm's native map coalescing, so you only set what changes.

```yaml
workload:
  type: "StatefulSet"

  # TCP health check
  livenessProbe:
    enabled: true
    type: "tcp"
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3

  # HTTP health check
  readinessProbe:
    enabled: true
    type: "http"
    path: "/health"
    periodSeconds: 5
    timeoutSeconds: 3
    failureThreshold: 2

  # Startup probe for slow-starting apps
  startupProbe:
    enabled: true
    type: "http"
    path: "/health"
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 6
```

### Override a single field

```yaml
workload:
  type: "StatefulSet"
  readinessProbe:
    periodSeconds: 15    # only this changes; type/path/port stay default
```

### Custom probe (`spec` verbatim)

Set `custom: true` with a raw `spec` to bypass the structured fields entirely.

```yaml
workload:
  type: "StatefulSet"
  livenessProbe:
    custom: true
    spec:
      httpGet:
        path: /live
        port: 8080
      initialDelaySeconds: 10
```

> ⚠️ **Fail-loud validation**: an unsupported `type`, or `type: exec` without a
> `command`, aborts the render with a clear error.

## Generated Resources

When you enable StatefulSet, the following resources are created:

- **StatefulSet**: Main workload with volumeClaimTemplates
- **Headless Service**: For stable network identity (`<fullname>-cluster`, or `workload.serviceName`)
- **Regular Service**: For external access (if service.enabled: true)
- **ServiceAccount**: For RBAC (if serviceAccount.create: true)
- **PVCs**: Created automatically per pod via volumeClaimTemplates

## Key Differences from Deployment

- **Stable Network Identity**: Pods have predictable names (app-0, app-1, etc.)
- **Ordered Deployment**: Pods are created/deleted in order
- **Persistent Storage**: Each pod gets its own PVC automatically
- **Headless Service**: Required for StatefulSet, provides stable DNS
- **VolumeClaimTemplates**: PVCs are created automatically, not manually

## Best Practices

1. **Use ReadWriteOnce** for most databases (only one pod can mount)
2. **Set appropriate resource limits** to prevent resource exhaustion
3. **Use external secrets** for sensitive data like passwords
4. **Configure health checks** for better reliability
5. **Use headless service** for internal communication between pods
6. **Plan for scaling** - StatefulSets scale differently than Deployments
