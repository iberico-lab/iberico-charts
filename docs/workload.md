# Workload

> **In one line:** the `workload:` block says **what to run**: the image, how many
> copies, which port, and which kind of workload.

---

## Which kind do I need?

| Pick… | When your app… | Examples |
|-------|----------------|----------|
| **`Deployment`** (default) | Doesn't care which copy handles a request | websites, APIs, workers |
| **`StatefulSet`** | Needs a fixed name and **its own disk per copy** | databases, queues |

Not sure? Use `Deployment`. For the other one, see [StatefulSet](statefulset.md).

---

## Copy-paste starter

```yaml
workload:
  type: "Deployment"
  image:
    repository: ghcr.io/example/app
    tag: "1.2.3"
  replicas: 3                 # number of copies
  applicationPort: 8080       # port the app listens on
  environment:                # plain (not secret) settings
    LOG_LEVEL: "info"
```

---

## Common tweaks

**Change the start command**: leave these out to use the image's own command.

```yaml
workload:
  command: ["/bin/sh"]                 # replaces the image's ENTRYPOINT
  args: ["-c", "exec my-app --fast"]   # replaces the image's CMD
```

**Read a value from Kubernetes** (the pod's own name, a key from another
Secret…): `extraEnv` takes normal Kubernetes env entries.

```yaml
workload:
  extraEnv:
    - name: POD_NAME
      valueFrom:
        fieldRef: { fieldPath: metadata.name }
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef: { name: my-db, key: password }
  extraEnvFrom:                       # load every key of a ConfigMap/Secret
    - configMapRef: { name: my-app-settings }
```

**Give it more (or less) CPU and memory:**

```yaml
workload:
  resources:
    requests: { cpu: 300m, memory: 512Mi }    # what it's guaranteed
    limits:   { cpu: 1000m, memory: 800Mi }   # the most it can use
```

> The values above are the defaults.

**Open more than one port**: see [Service → multiple ports](service.md#more-than-one-port).

---

## Gotchas

- **Never put passwords in `environment`.** Anyone who can read the values file
  can see them. Use [External Secrets](external-secrets.md) instead.
- `type` is case-sensitive: only `Deployment` or `StatefulSet`. Anything else stops
  the render with an error.
- **Always quote the image tag:** `tag: "1.10"`. Unquoted, YAML reads `1.10` as the
  number `1.1`, so the chart stops with an error asking you to quote it.
- Changing `applicationPort`? Also set `service.targetPort`. See [Service](service.md).

---

## All settings

| Setting | Default | What it does |
|---------|---------|--------------|
| `workload.enabled` | `true` | Turn the whole workload on/off |
| `workload.type` | `Deployment` | `Deployment` or `StatefulSet` |
| `workload.image.repository` | `nginx` | Image to run |
| `workload.image.tag` | `1.25` | Image version |
| `workload.image.pullPolicy` | `IfNotPresent` | When to download the image again |
| `workload.replicas` | `2` | Number of copies |
| `workload.applicationPort` | `80` | Port the app listens on |
| `workload.ports` | `[]` | List of named ports. If set, used instead of `applicationPort` |
| `workload.command` | `[]` | Start command (`[]` = image default) |
| `workload.args` | `[]` | Start arguments (`[]` = image default) |
| `workload.environment` | `{}` | Plain settings as `KEY: value` |
| `workload.extraEnv` | `[]` | Raw env entries (supports `valueFrom`) |
| `workload.extraEnvFrom` | `[]` | Raw `envFrom` entries (whole ConfigMaps/Secrets) |
| `workload.resources` | see above | CPU and memory |
| `workload.annotations` | `{}` | Annotations on the Deployment/StatefulSet |
| `workload.pod.annotations` | `{}` | Annotations on each pod |
| `workload.strategy` | rolling update, 1 at a time | How a Deployment rolls out updates |
| `workload.terminationGracePeriodSeconds` | `30` | Seconds the app gets to shut down cleanly |

---

## Next

- [Health checks](probes.md) · [Sidecars](sidecars.md) · [StatefulSet](statefulset.md)
