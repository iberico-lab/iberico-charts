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

**Stopping without dropped requests (on by default).** When a pod stops,
Kubernetes takes it out of the Service *and* sends it the stop signal at the
same time. For a moment, traffic still arrives at a pod that is shutting down,
which shows up as 502 errors during every update. So the chart makes a stopping
pod wait `shutdownDelaySeconds` (5) before the signal. Slow ingress? Raise it:

```yaml
workload:
  shutdownDelaySeconds: 10            # must stay below terminationGracePeriodSeconds (30)
```

**Run something just before the app stops.** Your own `preStop` replaces the
built-in wait, so add the wait to it if you still want it:

```yaml
workload:
  lifecycle:
    preStop:
      exec:
        command: ["sh", "-c", "sleep 5 && /app/drain"]
```

**How updates roll out.** By default a new pod starts and becomes ready
**before** an old one stops (`maxUnavailable: 0`, `maxSurge: 1`), so there's no
downtime, even with 1 replica. One exception, chosen for you: when the pods use
a ReadWriteOnce disk from `persistence`, only one pod can hold the disk, so old
pods stop first (`Recreate`), with a short downtime. To choose yourself:

```yaml
workload:
  strategy:
    type: RollingUpdate               # or Recreate; "" = automatic (the default)
    rollingUpdate: { maxUnavailable: 0, maxSurge: 2 }   # faster: 2 new pods at a time
```

**Give it more (or less) CPU and memory:**

```yaml
workload:
  resources:
    requests: { cpu: 500m, memory: 1Gi }   # what it's guaranteed (and how pods are placed)
    limits:   { memory: 2Gi }              # the most memory it can use
```

> Defaults: requests `100m` CPU / `128Mi` memory, limit `512Mi` memory, **no CPU
> limit**. A CPU limit slows your app down even when the node has CPU to spare,
> so add one only if you need to cap a noisy app: `limits: { cpu: "1" }`.

**Open more than one port**: see [Service → multiple ports](service.md#more-than-one-port).

---

## Gotchas

- **Never put passwords in `environment`.** Anyone who can read the values file
  can see them. Use [External Secrets](external-secrets.md) instead.
- `type` is case-sensitive: only `Deployment` or `StatefulSet`. Anything else stops
  the render with an error.
- **Pod killed with `OOMKilled`?** It used more than the memory limit (`512Mi` by
  default). Raise `resources.limits.memory`.
- **App reads `<SERVICE>_PORT` / `<SERVICE>_SERVICE_HOST` env vars** for other
  Services? The chart turns those off (`enableServiceLinks: false`), because they
  can clash with your own settings. Use the DNS name instead
  (`my-db.<namespace>.svc`), or set `enableServiceLinks: true`.
  `KUBERNETES_SERVICE_HOST` is always there.
- **Always quote the image tag:** `tag: "1.10"`. Unquoted, YAML reads `1.10` as the
  number `1.1`, so the chart stops with an error asking you to quote it.
- **Want the exact same image every time?** A tag like `1.25` can be re-pushed
  with different contents. A digest can't. Set
  `digest: "sha256:..."` (find it with `docker buildx imagetools inspect nginx:1.25`).
  Keep the tag too: it only shows humans which version it is.

---

## All settings

| Setting | Default | What it does |
|---------|---------|--------------|
| `workload.enabled` | `true` | Turn the whole workload on/off |
| `workload.type` | `Deployment` | `Deployment` or `StatefulSet` |
| `workload.image.repository` | `nginx` | Image to run |
| `workload.image.tag` | `1.25` | Image version |
| `workload.image.digest` | `""` | Pin the exact image (`sha256:...`); wins over the tag |
| `workload.image.pullPolicy` | `IfNotPresent` | When to download the image again |
| `workload.replicas` | `2` | Number of copies. 2 is the minimum to survive a pod or node going down; 3 for high availability ([why](availability.md#how-many-replicas)) |
| `workload.applicationPort` | `80` | Port the app listens on |
| `workload.ports` | `[]` | List of named ports. If set, used instead of `applicationPort` |
| `workload.command` | `[]` | Start command (`[]` = image default) |
| `workload.args` | `[]` | Start arguments (`[]` = image default) |
| `workload.environment` | `{}` | Plain settings as `KEY: value` |
| `workload.extraEnv` | `[]` | Raw env entries (supports `valueFrom`) |
| `workload.extraEnvFrom` | `[]` | Raw `envFrom` entries (whole ConfigMaps/Secrets) |
| `workload.resources` | see above | CPU and memory |
| `workload.lifecycle` | `{}` | `postStart` / `preStop` hooks, copied as-is |
| `workload.annotations` | `{}` | Annotations on the Deployment/StatefulSet |
| `workload.pod.annotations` | `{}` | Annotations on each pod |
| `workload.pod.labels` | `{}` | Extra labels on each pod (the chart's own labels can't be overridden) |
| `workload.strategy.type` | `""` | `RollingUpdate`, `Recreate`, or `""`: Recreate with a ReadWriteOnce disk, else RollingUpdate |
| `workload.strategy.rollingUpdate.maxUnavailable` | `0` | Old pods that may be down during a rolling update (number or `"25%"`) |
| `workload.strategy.rollingUpdate.maxSurge` | `1` | Extra new pods started at a time (number or `"25%"`) |
| `workload.terminationGracePeriodSeconds` | `30` | Seconds the app gets to shut down cleanly |
| `workload.shutdownDelaySeconds` | `5` | Seconds a stopping pod keeps serving before the stop signal (`0` = off; skipped if you set a `preStop`) |
| `workload.enableServiceLinks` | `false` | Add `<SERVICE>_PORT`-style env vars for every Service in the namespace |

---

## Next

- [Health checks](probes.md) · [Sidecars](sidecars.md) · [StatefulSet](statefulset.md)
