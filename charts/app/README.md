# app

Run any application on Kubernetes from one short values file: Deployment or
StatefulSet, Service, health checks, disks, 1Password secrets, Tailscale /
public ingress, autoscaling and metrics. Every feature has a working default.

## Quick start

```yaml
# values.yaml
workload:
  image:
    repository: ghcr.io/example/app
    tag: "1.2.3"
  applicationPort: 8080
```

```bash
helm dependency update ./charts/app
helm install my-app ./charts/app -f values.yaml
```

After installing, Helm prints how to reach the app (in-cluster address, URLs,
port-forward command). See it again with `helm get notes my-app`.

## Learn more

- [Getting started](https://github.com/iberico-lab/iberico-charts/blob/main/docs/getting-started.md)
- [All docs](https://github.com/iberico-lab/iberico-charts/blob/main/docs/index.md) · [Values reference](https://github.com/iberico-lab/iberico-charts/blob/main/docs/values-reference.md)
- [Examples](https://github.com/iberico-lab/iberico-charts/blob/main/examples/README.md) · [Troubleshooting](https://github.com/iberico-lab/iberico-charts/blob/main/docs/troubleshooting.md)
- [Upgrading](https://github.com/iberico-lab/iberico-charts/blob/main/docs/upgrading.md) · [Changelog](https://github.com/iberico-lab/iberico-charts/blob/main/CHANGELOG.md)

Values are checked against `values.schema.json`, so typos fail with a clear message.
