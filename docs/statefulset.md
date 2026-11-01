# StatefulSet

> **In one line:** use a StatefulSet when each copy of your app needs **its own
> fixed name and its own disk**. Databases are the classic case.

---

## Do I need one?

**Yes**, if your app:

- stores data that must survive restarts, **and**
- needs each copy to have its own disk, or a fixed name (`app-0`, `app-1`, …).

Typical cases are **databases, message queues and clustered systems**.

**No**: a website, API or worker should use a normal [Deployment](workload.md).

---

## Copy-paste starter

Switch it on with **one line**, then add a disk:

```yaml
workload:
  type: "StatefulSet"        # ← this is the switch
  image:
    repository: postgres
    tag: "16"
  replicas: 1
  applicationPort: 5432

persistence:                 # each copy gets its own disk like this
  - name: data
    size: 10Gi
    mountPath: /var/lib/postgresql/data
    accessModes: ["ReadWriteOnce"]

service:
  port: 5432
  targetPort: 5432
```

---

## What you get

| Thing | Name |
|-------|------|
| StatefulSet (your pods) | `<app>` → pods `<app>-0`, `<app>-1`, … |
| Headless Service (gives each pod a fixed address) | `<app>-cluster`, or `service.headless.name` |
| Normal Service | `<app>` (if `service.enabled`) |
| One disk **per pod** | `<disk name>-<app>-0`, `<disk name>-<app>-1`, … |

 Each pod can be reached at `<app>-0.<app>-cluster`, `<app>-1.<app>-cluster`, and so on.

---

## Recipes

> These use plain passwords to keep them short. **In real use, load passwords
> from [External Secrets](external-secrets.md).**

<details>
<summary><b>PostgreSQL</b></summary>

```yaml
workload:
  type: "StatefulSet"
  image: { repository: postgres, tag: "16" }
  applicationPort: 5432
  environment:
    POSTGRES_DB: "mydb"
    PGDATA: "/var/lib/postgresql/data/pgdata"
  livenessProbe:  { type: "tcp" }
  readinessProbe: { type: "tcp" }
  startupProbe:   { type: "tcp" }

persistence:
  - name: data
    size: 20Gi
    accessModes: ["ReadWriteOnce"]
    mountPath: /var/lib/postgresql/data

service: { port: 5432, targetPort: 5432 }
```
</details>

<details>
<summary><b>Redis</b></summary>

```yaml
workload:
  type: "StatefulSet"
  image: { repository: redis, tag: "7-alpine" }
  applicationPort: 6379
  livenessProbe:  { type: "tcp" }
  readinessProbe: { type: "tcp" }
  startupProbe:   { type: "tcp" }

persistence:
  - name: data
    size: 10Gi
    accessModes: ["ReadWriteOnce"]
    mountPath: /data

service: { port: 6379, targetPort: 6379 }
```
</details>

<details>
<summary><b>RabbitMQ</b></summary>

```yaml
workload:
  type: "StatefulSet"
  image: { repository: rabbitmq, tag: "3-management" }
  applicationPort: 5672
  livenessProbe:  { type: "tcp" }
  readinessProbe: { type: "tcp" }
  startupProbe:   { type: "tcp" }

persistence:
  - name: data
    size: 10Gi
    accessModes: ["ReadWriteOnce"]
    mountPath: /var/lib/rabbitmq

service: { port: 5672, targetPort: 5672 }
```
</details>

---

## Gotchas

- Databases don't answer HTTP on `/`, so the default probes will fail. Switch
  them to `type: "tcp"` like the recipes above. See [Health checks](probes.md).
- Each pod gets its own disk, so the default `ReadWriteOnce` is what you want.
- Adding replicas does **not** turn a single-node database into a cluster.
  The app itself has to support clustering.
- Deleting the release does **not** delete the per-pod disks. That's on
  purpose, so you don't lose data. Clean them up by hand if you really want them gone.

---

## StatefulSet-only settings

| Setting | Default | What it does |
|---------|---------|--------------|
| `workload.updateStrategy` | `{type: RollingUpdate}` | How pods are updated |
| `workload.podManagementPolicy` | `""` | `OrderedReady` (one pod at a time) or `Parallel` (all at once) |
| `service.headless.name` | `""` | Name of the headless Service (`""` = `<app>-cluster`) |
| `service.headless.port` | `null` | Headless Service port (`null` = `applicationPort`) |
| `service.headless.targetPort` | `null` | Headless Service target port (`null` = `applicationPort`) |
| `service.headless.ports` | `[]` | Several ports for the headless Service |
| `service.headless.annotations` | `{}` | Headless Service annotations |

Everything else (image, probes, sidecars, secrets…) works the same as for a
Deployment. See [Workload](workload.md).

---

## Next

- Example: [13 statefulset](../examples/13-statefulset/README.md) · [Persistence](persistence.md)
