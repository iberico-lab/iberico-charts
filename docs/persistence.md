# Persistence

> **In one line:** `persistence:` gives your app a disk that **keeps its data**
> when the app restarts or moves.

Note: `persistence:` is a **top-level** key. It does **not** go inside `workload:`.

---

## Persistence or Volumes?

| You need… | Use |
|-----------|-----|
| A **new disk that the chart creates** and that keeps data | **Persistence** (this page) |
| To mount something that **already exists** (config file, secret, existing disk, temp folder) | [Volumes](volumes.md) |

---

## Copy-paste starter

```yaml
workload:
  replicas: 1                     # one pod per ReadWriteOnce disk (see below)

persistence:
  - name: data                    # short name for this disk
    size: 20Gi                    # how big
    mountPath: /var/lib/data      # where the app sees it
    storageClassName: "fast-ssd"  # which kind of storage (ask your cluster admin)
```

Need more than one disk? Add more items to the list.

---

## What gets created depends on the workload type

| `workload.type` | You get |
|-----------------|---------|
| `Deployment` | **One shared disk** per entry, named `<app>-<name>` |
| `StatefulSet` | **One disk per copy** of the app (`<name>-<app>-0`, `-1`, …) |

---

## Gotchas

- **The default access mode is `ReadWriteOnce`** (one node at a time), which every
  storage type supports. Need several pods on different nodes to share one
  disk? Use a storage class that supports `ReadWriteMany` and set it explicitly.
- `ReadWriteOnce` + a Deployment with `replicas` > 1 (or autoscaling) means only
  one copy can use the disk, and the others would hang in `ContainerCreating`.
  The chart stops with an error instead. Use 1 replica, or switch to a
  [StatefulSet](statefulset.md) (one disk per copy).
- Using `storageClassName: "opendrive"`? The chart adds the rclone settings for you.
  The storage path defaults to the app name and the umask defaults to `022`. Change them with
  `rclone: { storagePath: ..., umask: ..., annotations: {...} }`.

---

## All settings (per list item)

| Setting | Default | What it does |
|---------|---------|--------------|
| `name` | — **required** | Short name for the disk |
| `size` | — **required** | Size, e.g. `10Gi` |
| `mountPath` | — **required** | Folder inside the container |
| `accessModes` | `["ReadWriteOnce"]` | Who can use the disk at once |
| `storageClassName` | cluster default | Kind of storage |
| `readOnly` | `false` | Mount as read-only |
| `annotations` | `{}` | Extra annotations on the disk (PVC) |
| `rclone` | — | Only for `opendrive`: `storagePath`, `umask`, `annotations` |

---

## Next

- Example: [09 persistence](../examples/09-persistence/README.md) · [Volumes](volumes.md) · [StatefulSet](statefulset.md)
