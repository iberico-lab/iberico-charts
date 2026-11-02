# Changelog

All notable changes to these charts. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions apply to all four charts, which are released together.

Upgrading? Read **[docs/upgrading.md](docs/upgrading.md)** first: it lists every step you have to do by hand.

## [0.3.0] - unreleased

### Breaking

- Resource names default to the **release name** when `global.name` is empty (was always `app`).
- No Kubernetes API token is mounted by default (`serviceAccount.automount: false`).
- `persistence` defaults to `ReadWriteOnce` (was `ReadWriteMany`).
- StatefulSet headless Service settings moved to `service.headless`: `workload.service.*` →
  `service.headless.*`, `workload.serviceName` → `service.headless.name`. The old keys fail with a
  message saying where they went.
- `service.targetPort` defaults to `workload.applicationPort` (was `80`).
- `ingresses[].name` renamed to `ingresses[].serviceName`; the old key fails with a message.
- Smaller default resources: requests `100m`/`128Mi`, memory limit `512Mi`, no CPU limit
  (was `300m`/`512Mi` and `1000m`/`800Mi`).
- Unknown or mistyped values are rejected by `values.schema.json`.
- Needs Kubernetes 1.30 or newer (`kubeVersion` in every chart). CI installs on 1.30, 1.34 and 1.37,
  with Helm 3 and 4.
- Rolling updates start new pods before stopping old ones (`maxUnavailable: 0`); Deployments with a
  ReadWriteOnce disk use `Recreate` (`workload.strategy.type: ""` = automatic).
- `enableServiceLinks: false`: no `<SERVICE>_PORT`-style env vars (`workload.enableServiceLinks`).

### Added

- Releases: tag `vX.Y.Z` to publish all four charts as a Helm repository on GitHub Pages
  (`https://iberico-lab.github.io/iberico-charts`) with a GitHub Release carrying the `.tgz` files.
- `values.schema.json` for the app, ingress and external-secrets charts.
- Install notes that print in-cluster DNS, Tailscale/public URLs and a port-forward command; `ingress.tailnetDomain`.
- `podDisruptionBudget`, `autoscaling` (HPA), `topologySpread` preset (on by default: pods prefer
  different nodes), `topologySpreadConstraints`, `priorityClassName`.
- Install notes warn when fewer than 2 replicas run, note that 3 is needed for high availability,
  and warn when nothing spreads the pods across nodes.
- `metrics.serviceMonitor` (Prometheus Operator).
- `securityPreset: restricted`: everything the restricted Pod Security Standard requires, also on
  sidecars; forbidden settings fail the render.
- Gateway API: `ingress.httpRoutes` and `ingress.gateway` create HTTPRoutes next to (or instead of)
  Ingresses.
- `networkPolicy` (opt-in): only the app's namespace and listed namespaces may connect.
- `workload.extraEnv`, `workload.extraEnvFrom`, `workload.pod.labels`, `workload.lifecycle`,
  `workload.podManagementPolicy`, `workload.reloadOnSecretChange` (Stakater Reloader).
- `extraManifests` for shipping extra objects with the release.
- `workload.shutdownDelaySeconds` (default 5): stopping pods keep serving briefly, so updates don't
  drop requests.
- `workload.image.digest` to pin the exact image (`repo:tag@sha256:...`).
- `workload.configFiles`: write config files in your values (`/path: contents`); pods restart
  when a file changes.
- `helm test` support: a pod that checks every Service port accepts connections (`helmTest`).
- `service.portName`; `homepage.enabled` per ingress.
- An `app.kubernetes.io/version` label taken from the image tag (not the placeholder chart
  `appVersion`, which is removed).
- Safe security defaults: seccomp `RuntimeDefault`, `allowPrivilegeEscalation: false`.
- One switch for secrets: `external-secrets.enabled` (1Password is on by default inside it).
- Docs: security, availability & scaling, metrics, extra manifests, troubleshooting, versions
  (what to change for a new app release vs a chart release), per-chart READMEs.
- `make bump VERSION=x.y.z` sets one version on all four charts; CI checks they agree.
- CI: unit tests (helm-unittest), schema freshness check, kubeconform validation, and an
  end-to-end install, `helm test` and upgrade of real scenarios on a kind cluster (`make e2e`),
  including 1Password secrets through the real External Secrets Operator (fake store), config
  files, ingress and ServiceMonitor.

### Fixed

- Clear errors instead of broken output for: invalid names, unquoted numeric image tags,
  duplicate container names, unknown `workload.type`, `ReadWriteOnce` disks shared by several
  pods, impossible PodDisruptionBudgets and autoscaling ranges, unknown ServiceMonitor ports.
- Deployments now honour `workload.terminationGracePeriodSeconds`; one pod template is shared by
  Deployments and StatefulSets.
- No Services are created when `workload.enabled: false`.
- Tailscale ingress: the machine name now comes only from `host` (or the app's name), placed in
  `spec.tls.hosts` where the operator reads it. The `tailscale.com/hostname` annotation, which the
  operator only documents for Services and which disagreed with `host`, is gone. A full domain or
  invalid name in `host` now fails with a clear error.
- StatefulSets with `persistence` can be upgraded: disk templates no longer carry the
  version and chart labels, which Kubernetes refuses to change. Needs a one-time
  `--cascade=orphan` step (see docs/upgrading.md).

### Removed

- `charts/app/values.example.yaml` (use `examples/`).

## [0.2.0] - unreleased

### Breaking

- `app.kubernetes.io/version` removed from pod selectors, so `appVersion` bumps no longer break
  upgrades. Needs a one-time `--cascade=orphan` step.

### Fixed

- Several `onepassword.secrets` entries are merged into one ExternalSecret per kind instead of
  overwriting each other; duplicate keys fail.
- `tailscale.com/hostname` moved under annotations.
- StatefulSet PVC annotations rendered once; no bogus persistence volumes on StatefulSet pods.
- Unknown `workload.type`, missing public ingress `host`, and clashing or unknown ingress types fail
  with clear errors.
- StatefulSet headless Service follows `applicationPort`.
- Secrets are only wired into pods when the ExternalSecrets are actually rendered.

### Removed

- Unused values: `global.namespaceOverride`, `onepassword.secretStore`, maintainer emails.

## [0.1.0]

- Initial charts: app, external-secrets, ingress, helm-helpers.
