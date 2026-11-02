# 17 · High availability

> **In one line:** Keep the app up during node drains and upgrades, and **add pods when it gets busy**.

**Use this when:**
- Downtime matters
- Traffic goes up and down during the day

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/17-high-availability/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- 3 to 6 pods, scaled on CPU (HorizontalPodAutoscaler)
- At least 2 pods always running during maintenance (PodDisruptionBudget)
- Never two pods on the same node, so a node dying takes at most one
- 10 seconds for in-flight requests to finish before a pod stops

## Watch out

- Autoscaling needs metrics-server in the cluster
- Needs at least 3 nodes: with fewer, the extra pods stay Pending (strict spread).
  On a smaller cluster, delete `whenUnsatisfiable` to make spreading a preference

---

Learn more: [Availability & scaling](../../docs/availability.md) · Next: [18 · Metrics (Prometheus)](../18-metrics/README.md)
