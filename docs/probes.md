# Probes

## Overview

Health checks tell Kubernetes whether your container is alive and ready to serve
traffic. The chart supports three probes: **liveness**, **readiness**, and
**startup**.

## When to use

| Probe | When to use |
|-------|-------------|
| **liveness** | Restart the container if it hangs or deadlocks. |
| **readiness** | Stop sending traffic until the app is ready (e.g. still warming up). |
| **startup** | Give slow-starting apps time before liveness checks begin. |

All three are **enabled by default** with an HTTP check on `path: /`. Disable any
you don't need.

> **No global health-path value.** Probes rely solely on each probe's own `path`
> (last-resort default `"/"`). There is no shared health endpoint setting.

## Values

Each probe (`livenessProbe`, `readinessProbe`, `startupProbe`) shares these keys:

| Key | Type | Default (liveness / readiness / startup) | Description |
|-----|------|------------------------------------------|-------------|
| `enabled` | bool | `true` / `true` / `true` | Render this probe |
| `type` | string | `http` | `http`, `tcp`, `grpc`, or `exec` |
| `path` | string | `/` | HTTP path (type `http`) |
| `port` | int/null | `null` | Port; `null` uses `workload.applicationPort` |
| `custom` | bool | `false` | Emit `spec` verbatim instead |
| `spec` | map | `{}` | Raw probe spec (used when `custom: true`) |
| `initialDelaySeconds` | int | `0` / `0` / `5` | Delay before first check |
| `periodSeconds` | int | `10` / `5` / `5` | Seconds between checks |
| `timeoutSeconds` | int | `1` / `1` / `3` | Per-check timeout |
| `failureThreshold` | int | `3` / `3` / `30` | Failures before action |
| `successThreshold` | int | `1` / `1` / `1` | Successes to be considered healthy |

Type-specific keys:

| Type | Extra keys |
|------|-----------|
| `http` | `host`, `scheme` (`HTTP`/`HTTPS`), `httpHeaders` |
| `tcp` | `host` |
| `grpc` | `service` |
| `exec` | `command` (**required**) |

## Example

Partial override — set only what changes:

```yaml
workload:
  readinessProbe:
    periodSeconds: 15          # everything else stays default
  livenessProbe:
    type: "tcp"                # switch handler type
  startupProbe:
    enabled: false             # disable a probe
```

`exec` probe (command required):

```yaml
workload:
  livenessProbe:
    type: "exec"
    command: ["cat", "/tmp/healthy"]
```

Fully custom probe:

```yaml
workload:
  livenessProbe:
    custom: true
    spec:
      httpGet:
        path: /live
        port: 8080
      initialDelaySeconds: 10
```

## Related

- [Workload](workload.md)
- [Values Reference](values-reference.md)
