# `app` Chart Conventions

## Sensible defaults

Every feature ships a working default in `charts/app/values.yaml`, so a minimal values
file (name + image) already produces a running Deployment with service, probes,
and resources. Start minimal and override only what you need.

## Partial overrides via Helm native map coalescing

Helm merges your values over the chart defaults by **map key**. This means:

- Omitted nested keys keep their chart default.
- You never restate a default you are not changing.

```yaml
workload:
  readinessProbe:
    periodSeconds: 15    # ONLY this changes; type/path/port/port/timings stay default
```

This is why probe blocks are declared as full maps in `charts/app/values.yaml` — it
makes per-field override safe.

> Caveat: because coalescing is per-key, **lists are replaced, not merged**.
> `volumes`, `extraContainers`, `extraInitContainers`, `persistence`, and
> `ingress.ingresses` fully replace the default (which is empty for these, so it
> is rarely a problem).

## Fail-loud behavior

The chart aborts rendering with a clear error rather than emitting a broken
manifest when inputs are invalid:

| Condition | Error |
|-----------|-------|
| Probe `type` not in `http`/`tcp`/`grpc`/`exec` | `app.probe: unsupported probe type "<x>" (use http|tcp|grpc|exec)` |
| `type: exec` without `command` | `app.probe: type=exec requires workload.<probe>.command` |
| `extraContainers[]` without `name` | `workload.extraContainers[].name is required` |
| `extraInitContainers[]` without `name` | `workload.extraInitContainers[].name is required` |

This is intentional: fail fast during `helm template`/install instead of
deploying something that silently misbehaves.

## Required fields

- Every `extraContainers` / `extraInitContainers` entry **MUST** define `name`.
- `persistence[]` entries require `name`, `size`, and `mountPath`.
- Public ingress entries require `host` (internal ingress does not).

## Naming

- `global.name` is the single source of truth for resource names. It flows
  through `helm-helpers.fullname` (lowercased, truncated to 63 chars).
- `global.fullnameOverride` / `global.nameOverride` can override naming if
  needed, but prefer `global.name`.
- Selectors use `app.kubernetes.io/name` (from `global.name`) and
  `app.kubernetes.io/instance` (release name) — keep `global.name` stable across
  upgrades to avoid selector churn.

## Probes

- Prefer structured fields + partial overrides for common cases.
- Use `custom: true` + `spec` only for handlers the structured schema does not
  model.
- Disable a probe with `enabled: false` rather than deleting the block.
- `port: null` (the default) resolves to `workload.applicationPort` — set an
  explicit `port` only for non-default probe ports.

## StatefulSet vs Deployment

- **Deployment**: stateless apps; `persistence` becomes standalone PVCs;
  `strategy` controls rolling updates.
- **StatefulSet**: stateful apps needing stable identity/per-pod storage;
  `persistence` becomes `volumeClaimTemplates`; a headless service is always
  rendered (`workload.serviceName` or `<app>-cluster`); `updateStrategy` and
  `terminationGracePeriodSeconds` apply.

## Validation checklist

Always run before deploying:

```bash
helm dependency update ./charts/app
helm lint ./charts/app -f values-myapp.yaml
helm template my-app ./charts/app -f values-myapp.yaml
```

Confirm the rendered output contains the expected workload, service, and any
enabled subchart objects (Ingress, ExternalSecret).
