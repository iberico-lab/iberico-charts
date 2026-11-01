# 13 · Database (StatefulSet)

> **In one line:** Run a 3-copy PostgreSQL where **each copy has its own disk** and a fixed name.

**Use this when:**
- You run a database, queue or anything that needs its own disk per copy

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/13-statefulset/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- StatefulSet with pods `postgresql-0`, `-1`, `-2`
- A 20Gi disk **per pod**
- Headless Service `postgresql-cluster` + normal Service on 5432
- TCP health checks (databases don't speak HTTP)

## Watch out

- 3 copies is not the same as a Postgres cluster. Postgres itself has to be set up for replication

---

Learn more: [StatefulSet](../../docs/statefulset.md) · Next: [14 · Several ports](../14-multi-port-service/README.md)
