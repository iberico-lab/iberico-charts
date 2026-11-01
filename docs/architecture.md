# Architecture

## Overview

The `app` chart is a **parent chart**. It composes three subcharts declared in
`charts/app/Chart.yaml` and driven by a single `workload:` block.

| Subchart | Purpose | Enabled by |
|----------|---------|------------|
| `helm-helpers` | Naming, labels, selectors | always (no toggle) |
| `external-secrets` | 1Password secrets → env vars / files | `external-secrets.enabled: true` |
| `ingress` | Tailscale internal + Traefik public ingress | `ingress.enabled: true` |

## When to use

You don't choose this — it's how the chart is built. Understand it so you know
**why** features are grouped the way they are, and where a new capability should
live. If you need a brand-new reusable capability, add a sibling chart and wire
it into `charts/app/Chart.yaml`.

## How names are built

`helm-helpers` derives every resource name from `global.name`:

| Value | Default | Result |
|-------|---------|--------|
| `global.name` | `""` | falls back to the chart name |
| `global.nameOverride` | `""` | overrides chart name |
| `global.fullnameOverride` | `""` | overrides the full name |

Names are lowercased and truncated to 63 characters.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `global.name` | string | `""` | Base name for resources |
| `global.nameOverride` | string | `""` | Override chart name |
| `global.fullnameOverride` | string | `""` | Override full resource name |
| `global.namespaceOverride` | string | `""` | Override namespace |

## Example

```yaml
global:
  name: "my-app"          # -> Deployment "my-app", Service "my-app"
```

## Related

- [Workload](workload.md)
- [Values Reference](values-reference.md)
