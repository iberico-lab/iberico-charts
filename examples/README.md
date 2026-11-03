# Examples

> **In one line:** working values files you can copy. Each folder has a
> `values.yaml` and a short README.

## Try any example

From the repository root:

```bash
make deps                                                         # once
helm template demo charts/app -f examples/01-minimal-deployment/values.yaml
```

Or check that they all still render: `make examples`.

## The list

New here? Go through them **in order**. Each one adds one idea.

| # | Example | What it shows |
|---|---------|---------------|
| [01](01-minimal-deployment/README.md) | Minimal app | The smallest working setup: one nginx container plus a Service in front of it. |
| [02](02-command-args/README.md) | Change the start command | Run the container with your own command instead of the image's default. |
| [03](03-environment/README.md) | Environment variables | Pass plain settings (log level, mode…) to your app as environment variables. |
| [04](04-sidecars/README.md) | Sidecars | Run helper containers **next to** your app: a metrics exporter and a log tailer. |
| [05](05-init-containers/README.md) | Init containers | Run setup steps **before** your app starts: wait for a database, then write a file. |
| [06](06-probes-basic/README.md) | Default health checks | See the built-in health checks working with **zero probe config**. Only the port changes. |
| [07](07-probes-partial-override/README.md) | Change one probe setting | Change **just one field** of a health check. Everything else keeps its default. |
| [08](08-probes-custom/README.md) | Custom health checks | Three other kinds of check: raw YAML, a command, and a plain port check. |
| [09](09-persistence/README.md) | Keep data (disks) | Give a MySQL app two disks that survive restarts: `data` and `logs`. |
| [10](10-volumes/README.md) | Mount existing things | Mount a ConfigMap, a Secret, a temporary folder and an existing disk. |
| [11](11-service/README.md) | Service type & ports | Put the app behind a cloud **LoadBalancer**: port 80 outside → 8080 inside. |
| [12](12-ingress/README.md) | URLs (ingress) | Give the app two URLs: a **public** one and a **private** Tailscale one. |
| [13](13-statefulset/README.md) | Database (StatefulSet) | Run a 3-copy PostgreSQL where **each copy has its own disk** and a fixed name. |
| [14](14-multi-port-service/README.md) | Several ports | Open **three** ports at once: `http`, `grpc` and `metrics`. |
| [15](15-config-files/README.md) | Config files | Write an nginx config file **right in your values**. Change it and the pods restart by themselves. |
| [16](16-secrets-and-urls/README.md) | Secrets and URLs (a real web app) | A typical web app: passwords from **1Password**, a **private** Tailscale URL and a **public** HTTPS URL. |
| [17](17-high-availability/README.md) | High availability | Keep the app up during node drains and upgrades, and **add pods when it gets busy**. |
| [18](18-metrics/README.md) | Metrics (Prometheus) | Let **Prometheus** collect your app's metrics from a second port. |
| [19](19-strict-security/README.md) | Strict security | Lock the container down: **not root**, **read-only** filesystem, no extra Linux powers. |
| [20](20-gateway-routes/README.md) | Gateway routes for several environments | One values file for every environment: each URL picks **internal**, **public** or **public-sso**, the environment decides what that runs. |

## Ship a new version of your app

In any example, the app's version is `workload.image.tag`. To deploy a new
release, change that tag and run `helm upgrade`. Leave the chart versions
alone: they're for people changing these charts. Use real version tags, not
`latest`. More: [Versions](../docs/versioning.md).

For full explanations, see the [docs](../docs/index.md).
