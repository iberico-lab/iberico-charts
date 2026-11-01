# Availability & scaling

> **In one line:** keep your app running while the cluster does maintenance,
> and let it grow or shrink with traffic.

All of these are **off by default**. Turn on what you need.

---

## Keep pods running during maintenance (PodDisruptionBudget)

When someone drains a node (for an upgrade, say), Kubernetes moves pods away.
A PodDisruptionBudget tells it **how many of your pods it may take down at once**.

```yaml
workload:
  replicas: 3

podDisruptionBudget:
  enabled: true
  maxUnavailable: 1      # at most 1 pod down at a time (the default)
  # or: minAvailable: 2  # at least 2 pods always up ("50%" works too)
```

If you set `minAvailable`, it wins and `maxUnavailable` is ignored.

**Watch out**

- `minAvailable` must be **lower** than `replicas`. Otherwise no pod could ever
  be moved and node drains would hang forever, so the chart stops with an error.
- With `replicas: 1`, a budget can only delay maintenance, not prevent downtime.
  Run at least 2 replicas if you want no downtime.

---

## Next

- [Workload](workload.md) · [Values Reference](values-reference.md)
