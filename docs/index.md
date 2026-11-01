# iberico-charts Documentation

The `app` chart is a reusable **"Lego block" application chart**. It bundles
everything a Kubernetes app needs — workload, service, probes, secrets, ingress —
so you add features by **toggling values**, not by writing manifests.

> New here? Start with **[Getting Started](getting-started.md)**.

## Table of contents

| Doc | What it covers |
|-----|----------------|
| [Getting Started](getting-started.md) | Install your first app in 5 minutes |
| [Architecture](architecture.md) | How the parent chart composes subcharts |
| [Workload](workload.md) | Deployment vs StatefulSet, image, replicas, command/args |
| [Probes](probes.md) | Liveness, readiness, startup health checks |
| [Sidecars & Init Containers](sidecars.md) | Extra containers in the pod |
| [Persistence](persistence.md) | Persistent storage (PVCs / volumeClaimTemplates) |
| [Volumes](volumes.md) | ConfigMaps, secrets, emptyDir, existing PVCs |
| [Service](service.md) | Exposing the app inside the cluster |
| [StatefulSet](statefulset.md) | Stable identity + per-pod storage |
| [External Secrets](external-secrets.md) | 1Password secrets → env vars / files |
| [Ingress](ingress.md) | Tailscale internal + Traefik public routing |
| [Values Reference](values-reference.md) | Every field, type, and default |

## Feature cheat sheet

| I want to… | Go to |
|------------|-------|
| Deploy a simple web app | [Getting Started](getting-started.md) |
| Run a database with stable storage | [StatefulSet](statefulset.md) + [Persistence](persistence.md) |
| Mount a config file | [Volumes](volumes.md) |
| Add a health check | [Probes](probes.md) |
| Run a log shipper next to my app | [Sidecars](sidecars.md) |
| Inject a password from 1Password | [External Secrets](external-secrets.md) |
| Expose my app on the internet | [Ingress](ingress.md) |

## Design principles

- **Sensible defaults** — every feature has a working default in `app/values.yaml`.
- **Partial overrides** — set only what changes; the rest inherits defaults.
- **Fail-loud** — bad config aborts the render with a clear error instead of
  producing a broken manifest.
