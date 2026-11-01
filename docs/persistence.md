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
persistence:
  - name: data                    # short name for this disk
    size: 20Gi                    # how big
    mountPath: /var/lib/data      # where the app sees it
    accessModes: ["ReadWriteOnce"]
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

- **The default access mode is `ReadWriteMany`.** Many storage types don't
  support it, and then the disk gets stuck as "Pending". Most of the time you want
  `accessModes: ["ReadWriteOnce"]`.
- `ReadWriteOnce` + a Deployment with `replicas` > 1 = only one copy can use the
  disk. Use 1 replica, or switch to a [StatefulSet](statefulset.md).
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
| `accessModes` | `["ReadWriteMany"]` | Who can use the disk at once |
| `storageClassName` | cluster default | Kind of storage |
| `readOnly` | `false` | Mount as read-only |
| `annotations` | `{}` | Extra annotations on the disk (PVC) |
| `rclone` | — | Only for `opendrive`: `storagePath`, `umask`, `annotations` |

---

## Next

- Example: [09 persistence](../examples/09-persistence/README.md) · [Volumes](volumes.md) · [StatefulSet](statefulset.md)
