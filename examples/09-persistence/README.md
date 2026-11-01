# 09 - Persistence

## What this shows

Durable storage via the top-level `persistence` list. With
`workload.type: Deployment`, the chart renders one standalone
`PersistentVolumeClaim` per entry (named `<app>-<entry-name>`) and mounts each
into the main container at its `mountPath`.

## When to use

For a single-replica stateful app on a Deployment where you want durable data
but do not need StatefulSet semantics (stable network identity, per-pod PVCs).
For per-pod storage with stable identity, see example 13 (StatefulSet).

## Render it

```bash
helm template t <repo>/charts/app -f values.yaml
```

## Expected output

Two `PersistentVolumeClaim` objects (`persistence-app-data`,
`persistence-app-logs`) plus a `Deployment` whose main container has
`volumeMounts` for `/var/lib/mysql` and `/var/log/mysql` and matching `volumes`
referencing the claims.
