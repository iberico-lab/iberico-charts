# 13 - StatefulSet

## What this shows

Running a stateful workload with `workload.type: StatefulSet`. Compared with a
Deployment, the chart additionally renders:

- a **headless Service** named `<app>-cluster` (or `workload.serviceName`),
- **`volumeClaimTemplates`** from the top-level `persistence` list (one PVC per
  pod, stable per-pod storage),
- StatefulSet-specific fields `updateStrategy`, `serviceName`, and
  `terminationGracePeriodSeconds`.

## When to use

For databases, queues, and other workloads needing stable network identity and
per-pod persistent storage — here a 3-replica PostgreSQL cluster.

## Render it

```bash
helm template t <repo>/app -f values.yaml
```

## Expected output

A headless `Service` (`postgresql-cluster`, `clusterIP: None`), a regular
`Service` on port 5432, and a `StatefulSet` with `serviceName:
postgresql-cluster`, a `volumeClaimTemplates` entry for `data` (20Gi), and TCP
probes.
