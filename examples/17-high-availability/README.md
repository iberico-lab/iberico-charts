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

- 2 to 6 pods, scaled on CPU (HorizontalPodAutoscaler)
- At least 1 pod always running during maintenance (PodDisruptionBudget)
- Pods spread across nodes
- 10 seconds for in-flight requests to finish before a pod stops

## Watch out

- Autoscaling needs metrics-server in the cluster
- Spreading only helps if you have more than one node

---

Learn more: [Availability & scaling](../../docs/availability.md) · Next: [18 · Metrics (Prometheus)](../18-metrics/README.md)
