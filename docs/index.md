# iberico-charts docs

> **In one line:** the `app` chart runs your app on Kubernetes. You write a short
> values file, and the chart creates everything else.

**New here?** Go to **[Getting Started](getting-started.md)**. It takes about 5 minutes.

---

## I want to…

| I want to… | Read this |
|------------|-----------|
| Run my first app | [Getting Started](getting-started.md) |
| Change the image, replicas or start command | [Workload](workload.md) |
| Tell Kubernetes when my app is healthy | [Health checks (probes)](probes.md) |
| Run a helper container next to my app | [Sidecars & init containers](sidecars.md) |
| Keep data when the app restarts | [Persistence](persistence.md) |
| Add a config file, or mount a secret or temp folder | [Volumes](volumes.md) |
| Let other apps in the cluster reach mine | [Service](service.md) |
| Run a database or anything with "state" | [StatefulSet](statefulset.md) |
| Use passwords from 1Password | [External Secrets](external-secrets.md) |
| Put my app on a URL (private or public) | [Ingress](ingress.md) |
| Collect my app's metrics with Prometheus | [Metrics](metrics.md) |
| Keep it running during maintenance, or scale with traffic | [Availability & scaling](availability.md) |
| Lock down what the app is allowed to do | [Security](security.md) |
| Ship an extra object (ConfigMap, CronJob…) with my app | [Extra manifests](extra-manifests.md) |
| Fix an error or a pod that won't start | [Troubleshooting](troubleshooting.md) |
| Look up one exact setting | [Values Reference](values-reference.md) |
| Understand how the charts fit together | [Architecture](architecture.md) |
| Upgrade to a new chart version | [Upgrading](upgrading.md) |

Want working files to copy? See **[examples/](../examples/README.md)**.

---

## Three ideas behind the chart

1. **Good defaults.** Every feature already works out of the box. You only set what you want to change.
2. **Change one thing, keep the rest.** If you set one field in a block, every other field in that block keeps its default.
3. **Loud errors.** If a setting is wrong, the chart stops with a clear message. It won't quietly create something broken.
   A typo in a setting name (like `replica` instead of `replicas`) is caught too, because every chart has a `values.schema.json`.
