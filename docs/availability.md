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

## Scale with traffic (autoscaling)

Add pods when they get busy, remove them when it's quiet:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80      # add pods above 80% of requested CPU
  # targetMemoryUtilizationPercentage: 80 # optional, same idea for memory
```

**Watch out**

- `workload.replicas` is **ignored** while autoscaling is on. The autoscaler
  decides, and Helm upgrades no longer reset the count.
- The percentage is measured against `workload.resources.requests`. Without a
  CPU (or memory) request, the chart stops with an error.
- The cluster needs **metrics-server**. Without it, the autoscaler can't see usage.
- Combined with a PodDisruptionBudget, `minAvailable` is checked against `minReplicas`.

---

## Don't put all pods on one node (topology spread)

```yaml
topologySpread:
  enabled: true
  topologyKey: kubernetes.io/hostname    # spread across nodes
  # topologyKey: topology.kubernetes.io/zone   # or across zones
  whenUnsatisfiable: ScheduleAnyway      # best effort; DoNotSchedule = strict
```

The chart fills in which pods to spread (yours), so that's all you need. For
anything fancier, add raw entries to `topologySpreadConstraints: []`.

**Watch out:** with `DoNotSchedule`, pods stay **Pending** if there aren't
enough nodes or zones. Start with `ScheduleAnyway`.

---

## Important apps first (priority)

```yaml
priorityClassName: "high-priority"   # must already exist in the cluster
```

When the cluster is full, pods with a higher priority are scheduled first and
can push lower-priority pods out.

---

## Next

- [Workload](workload.md) · [Values Reference](values-reference.md)
