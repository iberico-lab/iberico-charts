# 18 · Metrics (Prometheus)

> **In one line:** Let **Prometheus** collect your app's metrics from a second port.

**Use this when:**
- You run kube-prometheus-stack (or the Prometheus Operator)

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/18-metrics/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- A Service with two ports: `http` and `metrics`
- A ServiceMonitor that scrapes `metrics` on `/metrics` every 30s

## Watch out

- Needs the Prometheus Operator CRDs, or the install fails
- The `release` label must match what your Prometheus looks for

---

Learn more: [Metrics](../../docs/metrics.md) · Next: [19 · Strict security](../19-strict-security/README.md)
