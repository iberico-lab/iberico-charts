# 09 · Keep data (disks)

> **In one line:** Give a MySQL app two disks that survive restarts: `data` and `logs`.

**Use this when:**
- Your app saves data that must not disappear

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/09-persistence/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- 2 disks (PVCs): `persistence-app-data` (20Gi) and `persistence-app-logs` (5Gi)
- Mounted at `/var/lib/mysql` and `/var/log/mysql`

## Watch out

- Change `storageClassName` to one your cluster actually has
- The password is in plain text **for the demo only**. Use [External Secrets](../../docs/external-secrets.md) for real
- Need one disk *per copy*? See [13 StatefulSet](../13-statefulset/README.md)

---

Learn more: [Persistence](../../docs/persistence.md) · Next: [10 · Mount existing things](../10-volumes/README.md)
