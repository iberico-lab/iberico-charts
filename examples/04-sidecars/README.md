# 04 - Sidecars (extraContainers)

## What this shows

Adding sidecar containers to the workload pod via `workload.extraContainers`.
Each list entry is emitted verbatim as a container in the pod spec, so any
valid Kubernetes container fields are supported. Every entry **must** define
`name` — the chart fails loudly otherwise.

## When to use

For helper processes that share the pod lifecycle with the app: metrics
exporters, log shippers, service-mesh proxies, or local cache daemons.

## Render it

```bash
helm template t <repo>/app -f values.yaml
```

## Expected output

The pod's `containers:` list contains the main container plus
`metrics-exporter` and `log-tailer`, exactly as written in `values.yaml`.
