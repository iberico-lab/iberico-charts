# Changelog

All notable changes to these charts. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions apply to all four charts, which are released together.

## [0.1.0] - 2026-11-02

First release. The charts are built to be installed from scratch: read
[docs/getting-started.md](docs/getting-started.md), or copy `examples/`.

### Added

- `app`: runs any container image as a Deployment or StatefulSet from a values file.
  Image, replicas, ports, command/args, environment, ConfigMaps from values, volumes,
  persistence, extra containers and init containers, resource limits.
- Health checks (liveness, readiness, startup) defaulting to HTTP on `applicationPort`,
  with TCP, exec and raw-spec variants.
- `service`: ClusterIP/NodePort/LoadBalancer on port 80, forwarding to
  `workload.applicationPort`; multiple named ports; an optional headless Service for
  StatefulSets.
- `ingress`: URLs through the Tailscale operator (`internal`) or Traefik (`public`,
  `public-sso`), with Gateway API `httpRoutes` and `gateway` as an alternative.
  The Traefik middleware each public ingress attaches is named in
  `ingress.middlewares`; empty attaches none.
- `external-secrets`: one switch (`external-secrets.enabled`) to turn 1Password items
  into env vars and files for the pod.
- Availability and scaling: `autoscaling` (HPA), `podDisruptionBudget`, a
  `topologySpread` preset that prefers different nodes, `priorityClassName`.
- Safety: `networkPolicy` (opt-in), `securityPreset: restricted` for the restricted
  Pod Security Standard, seccomp `RuntimeDefault`, no privilege escalation, and no
  Service-account token mounted by default.
- Operations: `metrics.serviceMonitor`, `extraManifests`, `workload.lifecycle`,
  `workload.shutdownDelaySeconds` (stopping pods keep serving briefly), rolling updates
  that start new pods before stopping old ones, and `helm test` connection checks.
- `values.schema.json` for the app, ingress and external-secrets charts: unknown or
  mistyped settings are rejected instead of silently ignored, and cross-field mistakes
  stop the render with a message naming the fix.
- Docs for every feature, 19 working examples, and per-chart READMEs.
- CI: helm-unittest suites, schema freshness, documentation coverage, kubeconform
  validation against Kubernetes 1.30 and current, every example rendered, and an
  end-to-end install, `helm test` and upgrade on kind clusters (Kubernetes 1.30, 1.34,
  1.37; Helm 3 and 4) including 1Password secrets through the real External Secrets
  Operator, config files, ingress and ServiceMonitor.
- Releases: tag `vX.Y.Z` to publish all four charts as a Helm repository on GitHub Pages
  (`https://iberico-lab.github.io/iberico-charts`), with a GitHub Release carrying the
  packaged charts.

### Notes

- Needs Kubernetes 1.30 or newer (`kubeVersion` in every chart) and Helm 3 or 4.
- There are no `appVersion`s: these charts run your image, so the
  `app.kubernetes.io/version` label comes from your image tag.
