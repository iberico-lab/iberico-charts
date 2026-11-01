# Availability & scaling

> **In one line:** keep your app running while the cluster does maintenance,
> and let it grow or shrink with traffic.

Spreading pods across nodes is **on by default**. Everything else is **off**
until you turn it on.

---

## How many replicas?

| Replicas | What survives | Use it for |
|----------|---------------|------------|
| `1` | Nothing: the app is down whenever its pod restarts, is moved, or its node fails | Dev, or apps that can't run twice (one disk, one writer) |
| `2` (default) | One pod or one node going down | **The minimum** for anything people rely on |
| `3` or more | One pod failing **while** another is being updated or moved | **High availability** |

```yaml
workload:
  replicas: 3
```

After every install and upgrade, the notes print a **WARNING** below 2 and a
**NOTE** at 2. With autoscaling on, they check `autoscaling.minReplicas` instead.

To survive a node dying, you need **both**: at least 2 replicas, **and** those
pods on different nodes. The chart does the second part for you (see
[Don't put all pods on one node](#dont-put-all-pods-on-one-node-topology-spread)).

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

**On by default.** Kubernetes is asked to put your pods on different nodes, so
one node dying doesn't take them all. You don't have to set anything.

The default is a **preference** (`ScheduleAnyway`): if there aren't enough
nodes, pods still start, some sharing a node. To make it a **rule**, or to
spread across zones:

```yaml
topologySpread:
  topologyKey: kubernetes.io/hostname    # spread across nodes (the default)
  # topologyKey: topology.kubernetes.io/zone   # or across zones (cloud clusters)
  whenUnsatisfiable: DoNotSchedule       # strict: never two pods on one node
```

The chart fills in which pods to spread (yours). For anything fancier, add raw
entries to `topologySpreadConstraints: []`.

**Watch out**

- **Strict (`DoNotSchedule`) needs enough nodes.** With 3 replicas and 2 nodes,
  the third pod stays **Pending**, and so can a rolling update's extra pod.
- **The preference is checked only when a pod starts.** If a node was down and
  comes back, pods don't move back to it on their own. They spread out again
  at the next rollout (`kubectl rollout restart`).
- **A node dying is not a drain.** A PodDisruptionBudget only protects against
  planned work (drains, upgrades). Against a node dying, only replicas on
  different nodes help.
- Turned it off (`topologySpread.enabled: false`) and set no
  `topologySpreadConstraints` or pod anti-affinity? The notes print a WARNING.

---

## Important apps first (priority)

```yaml
priorityClassName: "high-priority"   # must already exist in the cluster
```

When the cluster is full, pods with a higher priority are scheduled first and
can push lower-priority pods out.

---

## All settings

| Setting | Default | What it does |
|---------|---------|--------------|
| `podDisruptionBudget.enabled` | `false` | Create a PodDisruptionBudget |
| `podDisruptionBudget.minAvailable` | `null` | Pods that must stay up (number or `"50%"`); wins over `maxUnavailable` |
| `podDisruptionBudget.maxUnavailable` | `1` | Pods that may be down at once |
| `autoscaling.enabled` | `false` | Create a HorizontalPodAutoscaler (`workload.replicas` is then ignored) |
| `autoscaling.minReplicas` | `2` | Fewest pods |
| `autoscaling.maxReplicas` | `5` | Most pods |
| `autoscaling.targetCPUUtilizationPercentage` | `80` | Add pods above this % of requested CPU (`null` = off) |
| `autoscaling.targetMemoryUtilizationPercentage` | `null` | Same for memory (`null` = off) |
| `autoscaling.behavior` | `{}` | Scale-up/down tuning, copied as-is |
| `topologySpread.enabled` | `true` | Spread pods with the preset |
| `topologySpread.topologyKey` | `kubernetes.io/hostname` | Spread across nodes, or `topology.kubernetes.io/zone` |
| `topologySpread.maxSkew` | `1` | Allowed difference in pod count between nodes/zones |
| `topologySpread.whenUnsatisfiable` | `ScheduleAnyway` | `ScheduleAnyway` (best effort) or `DoNotSchedule` (strict) |
| `topologySpreadConstraints` | `[]` | Raw rules, added after the preset |
| `priorityClassName` | `""` | PriorityClass for the pods |

---

## Next

- [Workload](workload.md) · [Values Reference](values-reference.md)
