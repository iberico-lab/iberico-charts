---
name: helm-app-chart
description: >
  Use when you need to create, migrate, or deploy an application to Kubernetes
  using the reusable `app` Helm chart in the iberico-charts repository, or when
  changing the charts themselves. Covers writing a values file (image, ports,
  probes, env, config files, volumes, persistence, Deployment vs StatefulSet,
  1Password secrets, Tailscale/Traefik ingress, autoscaling, disruption
  budgets, metrics, security), the rules that make renders fail, and how to
  validate with helm template / helm test. Trigger on requests like "deploy X
  with the app chart", "make a Helm chart for X", "migrate X to the app chart",
  or "add a feature/subchart to the charts".
version: 2.0.0
author: Iberico Lab
license: MIT
keywords:
  - helm
  - kubernetes
  - app-chart
  - deployment
  - statefulset
  - subchart
---

# Deploying an app with the `app` chart

`charts/app` runs **any** app from a values file. Don't copy or fork the chart
per app, and don't add templates for one app: write a values file and install
`charts/app`. Every feature is a setting.

## Where the truth lives (read these, not your memory)

| Need | File |
|------|------|
| Every setting, its default and meaning | `docs/values-reference.md` |
| Exact allowed keys and types (unknown keys are rejected) | `charts/app/values.schema.json` |
| Defaults with comments | `charts/app/values.yaml` |
| Working, CI-tested values files | `examples/NN-*/values.yaml` (index: `examples/README.md`) |
| One page per feature, with gotchas | `docs/*.md` (index: `docs/index.md`) |
| What an error message means | `docs/troubleshooting.md` |

## Workflow

1. **Start from the closest example.** Pick it from the table below, copy its
   `values.yaml`, and change only what differs.
2. **Write the smallest values file that works.** Everything has a working
   default. Never restate a default.
3. **Render and read the output:**
   ```bash
   make deps                                            # once (fetches bundled subcharts)
   helm template my-app ./charts/app -f values-myapp.yaml
   helm lint ./charts/app -f values-myapp.yaml
   ```
   If it fails, the message says what to change. Look it up in
   `docs/troubleshooting.md` if it's unclear. Don't work around it.
4. **Install, then check:**
   ```bash
   helm install my-app ./charts/app -f values-myapp.yaml
   helm test my-app        # checks every Service port accepts connections
   ```

Smallest working file:

```yaml
workload:
  image:
    repository: ghcr.io/example/app
    tag: "1.2.3"           # always quoted
  applicationPort: 8080    # the port the app listens on
```

## Pick a starting point

| The app… | Example | Docs |
|----------|---------|------|
| is a plain web app | `01-minimal-deployment` | `workload.md` |
| needs a different start command | `02-command-args` | `workload.md` |
| reads plain settings from env vars | `03-environment` | `workload.md` |
| reads a config file | `15-config-files` | `volumes.md` |
| needs passwords | `16-secrets-and-urls` | `external-secrets.md` |
| needs a URL (Tailscale and/or public) | `12-ingress`, `16-secrets-and-urls` | `ingress.md` |
| needs Gateway API routes, the same values in several environments | `20-gateway-routes` | `ingress.md` |
| is a database / needs a disk per pod | `13-statefulset` | `statefulset.md`, `persistence.md` |
| needs a disk that survives restarts (one pod) | `09-persistence` | `persistence.md` |
| isn't HTTP (TCP, gRPC) or has odd health checks | `08-probes-custom` | `probes.md` |
| has several ports | `14-multi-port-service` | `service.md` |
| needs a helper container | `04-sidecars`, `05-init-containers` | `sidecars.md` |
| must stay up / scale with load | `17-high-availability` | `availability.md` |
| exposes Prometheus metrics | `18-metrics` | `metrics.md` |
| can run as non-root | `19-strict-security` | `security.md` |
| needs an extra object (CronJob, NetworkPolicy…) | — | `extra-manifests.md` |

## Rules that make or break a render

**Values merging**
- Maps merge with the defaults, so set only the field that changes:
  `readinessProbe: { periodSeconds: 15 }` keeps everything else.
- Lists **replace** the default (`volumes`, `persistence`, `ingress.ingresses`,
  `extraContainers`, `service.ports`…).
- Set a key to `null` to remove a default (e.g. `securityContext: { allowPrivilegeEscalation: null }`).
- Unknown or misplaced keys fail with `additional properties '…' not allowed`.
  Check the level the key sits at in `docs/values-reference.md`.

**Image and names**
- Quote the tag: `tag: "1.10"`. Unquoted, it's read as the number `1.1` and fails.
- `workload.image.digest: "sha256:…"` pins the exact image.
- Names default to the **release name**. `global.name` overrides it. Keep it
  stable across upgrades.

**Ports and probes**
- `workload.applicationPort` is the port the app listens on. The Service listens on
  `service.port` (80) and forwards to `applicationPort` automatically.
- The three probes default to **HTTP GET `/`** on `applicationPort`. For a
  non-HTTP app set `type: "tcp"` on **all three** (`livenessProbe`,
  `readinessProbe`, `startupProbe`), or the pods never become ready.
- `type: "exec"` needs `command`. `custom: true` uses `spec` verbatim.
- `service.portName` (default `http`, max 15 chars) names the single port; use it
  for databases, e.g. `postgres`.

**Config and secrets**
- Plain settings: `workload.environment: { KEY: value }`.
- Config files: `workload.configFiles: { /etc/app/config.yaml: "…" }`. Pods
  restart when a file changes. The volume name `config-files` is reserved.
- **Never put passwords in `environment` or `configFiles`.** Use
  `external-secrets` (1Password). `envVars` become env vars; `files` appear in
  `/etc/secrets/onepassword/`. Set `workload.reloadOnSecretChange: true` to
  restart on change (needs Stakater Reloader).
- `extraEnv` / `extraEnvFrom` are raw Kubernetes entries (fieldRef, other Secrets).

**Storage**
- `persistence` is **top-level**, not under `workload`. Entries need `name`,
  `size`, `mountPath`. `accessModes` defaults to `ReadWriteOnce`.
- A Deployment with more than one pod can't share a `ReadWriteOnce` disk: the
  render fails. Use `workload.type: StatefulSet` (one disk per pod), 1 replica,
  or a `ReadWriteMany` storage class.
- `workload.volumes` mounts things that **already exist** (ConfigMap, Secret,
  emptyDir, PVC).

**StatefulSets**
- `workload.type: "StatefulSet"` (case-sensitive). Each pod gets its own disk and
  address via a headless Service, configured in `service.headless`
  (`name` default `<app>-cluster`, `port`, `targetPort`, `ports`, `annotations`).

**URLs (ingress)**
- `type: internal` = Tailscale only. `host` is the **machine name** (`store`), not a
  domain; empty = the app's name. URL: `https://<host>.<tailnet>.ts.net`. Set
  `ingress.tailnetDomain` so the install notes print it.
- `type: public` / `public-sso` (SSO) need `host: app.example.com`. The
  issuer defaults to `letsencrypt-staging` (browser warning); set
  `certManagerIssuer: letsencrypt-prod` for real use.
- One ingress per type per release. `serviceName` picks a different backend Service.
- Gateway API (`ingress.httpRoutes`): need `ingress.gateway.name`. A route
  without `host` becomes `<subdomain or app name>.<ingress.domain>`. For login,
  write `access: sso` (or `public`) and let the environment name the Middleware
  in `ingress.accessProfiles`; never hard-code a Traefik `ExtensionRef` in app
  values. `access: sso` without `accessProfiles.sso.middleware` fails.

**Availability, scaling, metrics**
- `autoscaling.enabled` ignores `workload.replicas` and needs
  `workload.resources.requests.cpu` (and memory if you target memory).
- `podDisruptionBudget`: `minAvailable` wins over `maxUnavailable` and must be
  lower than the replica count.
- Replicas: 2 is the minimum for anything people rely on, 3 for high availability.
  The install notes warn below 2.
- `topologySpread` is on by default (`ScheduleAnyway` across nodes; the selector is
  filled in). `whenUnsatisfiable: DoNotSchedule` makes it strict.
- `metrics.serviceMonitor.port` is a Service port **name**; needs the Prometheus Operator CRDs.

**Resources and security**
- Defaults: requests `100m` CPU / `128Mi` memory, `512Mi` memory limit, no CPU
  limit. Raise them for heavy apps. `OOMKilled` means the memory limit is too low.
- Defaults: seccomp `RuntimeDefault`, `allowPrivilegeEscalation: false`, no API
  token mounted (`serviceAccount.automount: true` if the app calls the API).
  Stricter: `securityPreset: restricted` (non-root image needed; set
  `podSecurityContext.runAsUser` if the image's USER isn't numeric). See
  `docs/security.md` and example 19.
- `networkPolicy.enabled` limits who can connect; list the ingress controller,
  Tailscale and Prometheus namespaces in `networkPolicy.allowNamespaces`.
- Rollouts: `maxUnavailable: 0` by default, `Recreate` automatically with a
  ReadWriteOnce `persistence` disk; `shutdownDelaySeconds: 5` drains traffic
  (a custom `preStop` replaces it); `enableServiceLinks: false`.

## Versions

- New release of the app = change `workload.image.tag` (real versions, never
  `latest`) and `helm upgrade`. Never bump a chart version for this.
- The charts have no `appVersion`. The version label comes from the image tag.
- Changing the charts: `make bump VERSION=x.y.z` sets all four chart versions
  and the dependency pins together (before 1.0: breaking → minor, otherwise
  patch). Details: `docs/versioning.md`.

## Migrating an existing app

1. Map each piece of the old manifests to a setting using the pick-a-starting-point
   table: image, port, env (plain vs secret), config files, disks, URLs.
2. Secrets in the old manifests go to 1Password plus `external-secrets`, never into values.
3. Anything the chart has no setting for goes in `extraManifests` (templated
   with `tpl`, so `{{ include "helm-helpers.fullname" . }}` works).
4. Render, then compare with the old manifests: names, ports, probes, mounts.

## Changing the charts themselves

Read `references/conventions.md` (design rules) and
`references/subchart-pattern.md` (how the charts fit together). Then, for every change:

```bash
make bump VERSION=x.y.z   # when releasing (docs/versioning.md)
make schema        # after changing values.yaml (edit hack/gen-values-schema.py for new keys)
make docs-check    # every setting must appear in docs/
make test          # helm-unittest suites in charts/*/tests
make validate      # kubeconform on examples + charts/app/ci
make examples      # every example still renders
make e2e           # optional: real install on a throwaway cluster (KUBE_CONTEXT=...)
```

Add a unit test for new behaviour, a row in `docs/values-reference.md` and the
feature's page, and a `CHANGELOG.md` entry. A breaking change gets its own
section in the changelog.
