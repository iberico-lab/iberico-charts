# 04 · Sidecars

> **In one line:** Run helper containers **next to** your app: a metrics exporter and a log tailer.

**Use this when:**
- You need a log shipper, metrics exporter or proxy in the same pod

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/04-sidecars/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- The pod runs 3 containers: your app, `metrics-exporter` and `log-tailer`

## Watch out

- Every sidecar **must** have a `name`, or the chart stops with an error

---

Learn more: [Sidecars & init containers](../../docs/sidecars.md) · Next: [05 · Init containers](../05-init-containers/README.md)
