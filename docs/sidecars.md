# Sidecars & init containers

> **In one line:** add extra containers to your app's pod. **Init containers**
> run *before* your app starts. **Sidecars** run *next to* it the whole time.

---

## Which one?

| You want to… | Use | Examples |
|--------------|-----|----------|
| Do something **first**, then get out of the way | **init container** | wait for the DB, run migrations, download config |
| Run a helper **for as long as the app runs** | **sidecar** | log shipper, metrics exporter, proxy |

---

## Copy-paste starter

```yaml
workload:
  extraInitContainers:          # run first, one after another
    - name: wait-for-db
      image: busybox:1.36
      command: ["sh", "-c", "until nc -z db 5432; do sleep 2; done"]

  extraContainers:              # run next to the app
    - name: metrics-exporter
      image: prom/statsd-exporter:latest
      ports:
        - name: metrics
          containerPort: 9102
```

You write normal Kubernetes container YAML. The chart copies it into the pod
**exactly as written**.

---

## Gotchas

- **Every entry needs a `name`**, and names must be **unique** across your app,
  sidecars and init containers (your app's container is named after `global.name`).
  Otherwise the chart stops with an error.
- If an init container never finishes, your app never starts.
- Sidecars share the pod's network, so they can reach your app on `localhost`.

---

## All settings

| Setting | Default | What it does |
|---------|---------|--------------|
| `workload.extraContainers` | `[]` | Sidecars (copied as-is) |
| `workload.extraInitContainers` | `[]` | Init containers (copied as-is) |

---

## Next

- Examples: [04 sidecars](../examples/04-sidecars/README.md) · [05 init containers](../examples/05-init-containers/README.md)
