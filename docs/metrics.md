# Metrics (Prometheus)

> **In one line:** let Prometheus collect your app's metrics. Turn it on, and
> the chart creates the `ServiceMonitor` for you.

Needs the **Prometheus Operator** (for example `kube-prometheus-stack`) in the cluster.

---

## Copy-paste starter

**Metrics on the same port as the app:**

```yaml
metrics:
  serviceMonitor:
    enabled: true
    path: /metrics
    labels:
      release: kube-prometheus-stack   # so Prometheus picks it up (check your install)
```

**Metrics on their own port** ([several ports](service.md#more-than-one-port)):

```yaml
service:
  ports:
    - { name: http,    port: 80,   targetPort: 8080 }
    - { name: metrics, port: 9102, targetPort: 9102 }

metrics:
  serviceMonitor:
    enabled: true
    port: metrics          # the Service port NAME, not the number
```

---

## Watch out

- `port` is a **name** from your Service. If it doesn't exist, the chart stops
  with an error listing the names you have.
- Prometheus only reads ServiceMonitors that match its selector, usually a
  `release: <name>` label. If nothing shows up, check `labels`.
- Needs `service.enabled: true`.

---

## All settings

| Setting | Default | What it does |
|---------|---------|--------------|
| `metrics.serviceMonitor.enabled` | `false` | Create the ServiceMonitor |
| `metrics.serviceMonitor.port` | `""` | Service port name (`""` = first port) |
| `metrics.serviceMonitor.path` | `/metrics` | URL path |
| `metrics.serviceMonitor.interval` | `30s` | How often to scrape |
| `metrics.serviceMonitor.scrapeTimeout` | `""` | Per-scrape timeout |
| `metrics.serviceMonitor.labels` | `{}` | Extra labels (for Prometheus to find it) |

---

## Next

- [Service](service.md) · [Availability & scaling](availability.md)
