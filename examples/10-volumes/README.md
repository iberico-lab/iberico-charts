# 10 · Mount existing things

> **In one line:** Mount a ConfigMap, a Secret, a temporary folder and an existing disk.

**Use this when:**
- You want to mount something that **already exists** in the cluster

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/10-volumes/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- `/etc/app/config` ← ConfigMap (read-only)
- `/etc/app/tls` ← Secret (read-only)
- `/var/cache/app` ← temporary folder
- `/data` ← existing disk `shared-data-pvc`

## Watch out

- The ConfigMap, Secret and disk must exist **before** you install, or the pod won't start

---

Learn more: [Volumes](../../docs/volumes.md) · Next: [11 · Service type & ports](../11-service/README.md)
