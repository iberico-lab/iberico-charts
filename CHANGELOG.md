# Changelog

All notable changes to these charts. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions apply to all four charts, which are released together.

## [0.4.0] - 2026-11-02

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
  `public-sso`), as Ingresses or Gateway API `httpRoutes` with the same three types.
  Nothing is created until you list one.
- One hostname rule for every type: `host` as written, else
  `<subdomain or app name>[-<suffix>].<domain>`, with `domain` and `suffix` set per
  environment (`ingress.domain`, `ingress.types.<type>.domain` / `.suffix`), so app
  values don't need hostnames. Internal routes default to `internal.<domain>`, so one
  domain per environment gives `shop.<domain>` and `shop.internal.<domain>`.
  Tailscale Ingresses use the one-label `<label>.<tailnetDomain>` form.
- `docs/environments.md`: the Gateways, DNS (including Tailscale split DNS),
  certificates and Flux wiring behind one domain per environment.
- What each type runs is set once per environment in `ingress.types`: its Traefik
  middlewares (always run first, so an entry's own `middlewares` can't skip the
  login) and, for routes, its Gateway. `public-sso` without a login middleware, and
  an `internal` route without a private Gateway, stop the render. HTTPRoutes carry
  Homepage annotations like ingresses (`homepage.enabled: false` hides one).
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
- Docs for every feature, 20 working examples, and per-chart READMEs.
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
