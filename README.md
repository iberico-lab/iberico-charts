# Iberico Charts

> **In one line:** Helm charts that run your app on Kubernetes. You write a short
> values file, and the chart creates everything else.

**Full docs: [docs/](docs/index.md)** · **Copy-paste examples: [examples/](examples/README.md)** · **Something broken? [Troubleshooting](docs/troubleshooting.md)**

---

## Quick start

From the repository root:

```bash
helm dependency update ./charts/app       # or: make deps

helm install my-app ./charts/app \
  --set global.name=my-app \
  --set workload.image.repository=nginx \
  --set workload.image.tag=alpine
```

You get:

- A Deployment running 2 copies of your app
- A Service on port 80, reachable inside the cluster

After installing, Helm prints how to reach the app: in-cluster address, URLs and
a port-forward command.

Next: [Getting Started](docs/getting-started.md), a 5-minute guide that uses a values file.

---

## What it can do

Every feature is a few lines in your values file. Most are **off** until you turn them on.

| Feature | One-line summary | Docs |
|---------|------------------|------|
| Workload | Deployment or StatefulSet, image, replicas, start command | [Workload](docs/workload.md) |
| Health checks | Startup, readiness and liveness checks, on by default | [Probes](docs/probes.md) |
| Sidecars and init containers | Extra containers next to your app, or before it starts | [Sidecars](docs/sidecars.md) |
| Persistence | Disks that keep data across restarts | [Persistence](docs/persistence.md) |
| Volumes | Mount ConfigMaps, Secrets, temp folders, existing disks | [Volumes](docs/volumes.md) |
| Service | Stable address inside the cluster | [Service](docs/service.md) |
| StatefulSet | One disk and a fixed name per copy, for databases | [StatefulSet](docs/statefulset.md) |
| External Secrets | Passwords from 1Password as env vars or files | [External Secrets](docs/external-secrets.md) |
| Ingress | Private (Tailscale), public, or public with login | [Ingress](docs/ingress.md) |
| Metrics | Prometheus ServiceMonitor with one switch | [Metrics](docs/metrics.md) |
| Availability & scaling | PodDisruptionBudget, autoscaling, spread across nodes | [Availability](docs/availability.md) |
| Security | Safe defaults on, stricter settings one block away | [Security](docs/security.md) |
| Extra manifests | Ship any extra object (ConfigMap, CronJob…) with the app | [Extra manifests](docs/extra-manifests.md) |

---

## Repository layout

```text
charts/
  app/               # Main chart: the one you install
  external-secrets/  # Secrets from 1Password (used by app)
  ingress/           # Tailscale + Traefik URLs (used by app)
  helm-helpers/      # Shared naming/label code (used by all)
docs/                # Guides, one per feature. Start at docs/index.md
examples/            # Working values files, numbered 01-14
.github/
  configs/           # ct.yaml, cr.yaml, lintconf.yaml
  workflows/         # Lint + release pipelines
Makefile             # Shortcuts, see below
```

The charts refer to each other as neighbours (`file://../<name>`), so keep them
together in `charts/`.

---

## Handy commands

| Command | What it does |
|---------|--------------|
| `make deps` | Fetch the bundled charts (run this first) |
| `make lint` | Check every chart for mistakes |
| `make test` | Run the unit tests (needs the [helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin) |
| `make template` | Show the YAML the `app` chart creates with default values |
| `make examples` | Check that every example still works |
| `make e2e` | Install every `hack/e2e` scenario on a throwaway cluster, run `helm test`, check secrets and config reach the pod, upgrade (`KUBE_CONTEXT=...`) |
| `make validate` | Check the rendered YAML against Kubernetes schemas (needs [kubeconform](https://github.com/yannh/kubeconform)) |
| `make schema` | Regenerate `values.schema.json` after changing values |
| `make clean` | Delete downloaded chart files |

See [CHANGELOG.md](CHANGELOG.md) for what changed in each version.
