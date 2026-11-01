# Changelog

All notable changes to these charts. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions apply to all four charts, which are released together.

Upgrading? Read **[docs/upgrading.md](docs/upgrading.md)** first: it lists every step you have to do by hand.

## [0.3.0] - unreleased

### Breaking

- Resource names default to the **release name** when `global.name` is empty (was always `app`).
- No Kubernetes API token is mounted by default (`serviceAccount.automount: false`).
- `persistence` defaults to `ReadWriteOnce` (was `ReadWriteMany`).
- StatefulSet headless Service settings moved to `service.headless` (`workload.service` still works, deprecated).
- `service.targetPort` defaults to `workload.applicationPort` (was `80`).
- Unknown or mistyped values are rejected by `values.schema.json`.

### Added

- `values.schema.json` for the app, ingress and external-secrets charts.
- Install notes that print in-cluster DNS, Tailscale/public URLs and a port-forward command; `ingress.tailnetDomain`.
- `podDisruptionBudget`, `autoscaling` (HPA), `topologySpread` preset, `topologySpreadConstraints`, `priorityClassName`.
- `metrics.serviceMonitor` (Prometheus Operator).
- `workload.extraEnv`, `workload.extraEnvFrom`, `workload.pod.labels`, `workload.lifecycle`,
  `workload.podManagementPolicy`, `workload.reloadOnSecretChange` (Stakater Reloader).
- `extraManifests` for shipping extra objects with the release.
- `helm test` support: a pod that checks every Service port accepts connections (`helmTest`).
- `service.portName`; `ingresses[].serviceName` (`name` kept as an alias); `homepage.enabled` per ingress.
- `global.version` and an `app.kubernetes.io/version` label taken from the image tag.
- Safe security defaults: seccomp `RuntimeDefault`, `allowPrivilegeEscalation: false`.
- One switch for secrets: `external-secrets.enabled` (1Password is on by default inside it).
- Docs: security, availability & scaling, metrics, extra manifests, troubleshooting, per-chart READMEs.
- CI: unit tests (helm-unittest), schema freshness check, kubeconform validation.

### Fixed

- Clear errors instead of broken output for: invalid names, unquoted numeric image tags,
  duplicate container names, unknown `workload.type`, `ReadWriteOnce` disks shared by several
  pods, impossible PodDisruptionBudgets and autoscaling ranges, unknown ServiceMonitor ports.
- Deployments now honour `workload.terminationGracePeriodSeconds`; one pod template is shared by
  Deployments and StatefulSets.
- No Services are created when `workload.enabled: false`.
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
