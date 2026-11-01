# Getting Started

> **In one line:** write a small values file, then run two commands. Your app is running.

About 5 minutes. You need: `helm` and access to a Kubernetes cluster.

---

## Step 1 — Write a values file

Make a file called `values-myapp.yaml`:

```yaml
global:
  name: "my-app"            # names everything the chart creates (default: the release name)

workload:
  image:
    repository: nginx       # the container image to run
    tag: "1.25"
  applicationPort: 80       # the port your app listens on
  replicas: 2               # how many copies to run
```

That's a complete file. Everything else uses its default.

## Step 2 — Fetch the bundled charts

From the repository root:

```bash
helm dependency update ./charts/app
```

> Or run `make deps`, which does this for every chart.

## Step 3 — Preview (optional, but recommended)

This shows the Kubernetes YAML the chart would create. Nothing is installed.

```bash
helm template my-app ./charts/app -f values-myapp.yaml
```

## Step 4 — Install

```bash
helm install my-app ./charts/app -f values-myapp.yaml
```

Done. Your app is running.

Helm then prints **how to reach your app**: its address inside the cluster,
any URLs (Tailscale, public), and a `kubectl port-forward` command for a quick
test from your machine. Run `helm get notes my-app` to see it again later.

---

## What you get

| Thing | When |
|-------|------|
| Deployment (runs your pods) | Always, unless `workload.enabled: false` |
| Service (a stable address inside the cluster, port 80) | On by default |
| Ingress (a URL) | Only if you set `ingress.enabled: true` |
| Secrets from 1Password | Only if you set `external-secrets.enabled: true` |

---

## The #1 gotcha: the port

Is your app listening on a port **other than 80**? Then set **both** of these:

```yaml
workload:
  applicationPort: 8080     # where the app listens

service:
  targetPort: 8080          # where the Service sends traffic (default is 80!)
```

`service.targetPort` does **not** follow `applicationPort` on its own.

---

## Next

- Change more about your app → [Workload](workload.md)
- Give it a URL → [Ingress](ingress.md)
- Copy a ready-made example → [examples/](../examples/README.md)
